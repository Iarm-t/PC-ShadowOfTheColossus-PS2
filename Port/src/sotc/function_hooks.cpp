#include "sotc/function_hooks.h"
#include "sotc/log.h"

#include <array>
#include <atomic>
#include <iomanip>
#include <cstdlib>
#include <map>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace sotc
{
    namespace
    {
        struct Hook
        {
            FunctionBinding binding;
            GuestFunction original = nullptr;
            std::vector<EntryObserver> observers;
            std::shared_ptr<const std::vector<EntryObserver>> snapshot;
        };

        struct FastHookSlot
        {
            std::atomic<uint32_t> address{0u};
            std::atomic<const Hook *> hook{nullptr};
        };

        constexpr size_t kFastHookTableSize = 256u;
        constexpr size_t kFastHookTableMask = kFastHookTableSize - 1u;

        std::mutex g_mutex;
        std::unordered_map<uint32_t, Hook> g_hooks;
        std::array<FastHookSlot, kFastHookTableSize> g_fastHooks{};

        void publishFastHook(uint32_t address, const Hook *hook) noexcept
        {
            size_t idx = ((address >> 2u) * 2654435761u) & kFastHookTableMask;
            for (size_t probe = 0u; probe < kFastHookTableSize; ++probe)
            {
                const uint32_t slotAddr = g_fastHooks[idx].address.load(std::memory_order_relaxed);
                if (slotAddr == address || slotAddr == 0u)
                {
                    g_fastHooks[idx].hook.store(hook, std::memory_order_release);
                    g_fastHooks[idx].address.store(address, std::memory_order_release);
                    return;
                }
                idx = (idx + 1u) & kFastHookTableMask;
            }
        }

        const Hook *lookupFastHook(uint32_t address) noexcept
        {
            size_t idx = ((address >> 2u) * 2654435761u) & kFastHookTableMask;
            for (size_t probe = 0u; probe < kFastHookTableSize; ++probe)
            {
                const uint32_t slotAddr = g_fastHooks[idx].address.load(std::memory_order_acquire);
                if (slotAddr == address)
                    return g_fastHooks[idx].hook.load(std::memory_order_acquire);
                if (slotAddr == 0u)
                    return nullptr;
                idx = (idx + 1u) & kFastHookTableMask;
            }
            return nullptr;
        }

        const char *statusName(ReplacementStatus status)
        {
            switch (status)
            {
            case ReplacementStatus::Recompiled:
                return "recomp";
            case ReplacementStatus::Observed:
                return "recomp+observed";
            case ReplacementStatus::Native:
                return "native";
            case ReplacementStatus::Hle:
                return "hle";
            case ReplacementStatus::TemporaryStub:
                return "TEMPORARY-STUB";
            }
            return "?";
        }
    }

    FunctionHooks &FunctionHooks::instance()
    {
        static FunctionHooks hooks;
        return hooks;
    }

    void FunctionHooks::attach(PS2Runtime &runtime)
    {
        m_runtime = &runtime;
    }

    GuestFunction FunctionHooks::original(uint32_t address) const
    {
        if (const Hook *fast = lookupFastHook(address))
            return fast->original;
        std::lock_guard<std::mutex> lock(g_mutex);
        const auto it = g_hooks.find(address);
        return it == g_hooks.end() ? nullptr : it->second.original;
    }

    bool FunctionHooks::observeEntry(uint32_t address, std::string name, EntryObserver observer)
    {
        if (!m_runtime)
        {
            return false;
        }
        std::lock_guard<std::mutex> lock(g_mutex);
        auto it = g_hooks.find(address);
        if (it == g_hooks.end())
        {
            GuestFunction original = m_runtime->lookupFunction(address);
            if (!original)
            {
                SOTC_ERROR(Hook, "cannot observe 0x" << std::hex << address << " (" << name << "): no recompiled function");
                return false;
            }
            Hook hook;
            hook.binding = FunctionBinding{address, name, ReplacementStatus::Observed, "entry observer"};
            hook.original = original;
            it = g_hooks.emplace(address, std::move(hook)).first;
            if (!m_runtime->replaceFunction(address, &FunctionHooks::observedTrampoline))
            {
                g_hooks.erase(it);
                return false;
            }
        }
        it->second.observers.push_back(std::move(observer));
        it->second.snapshot = std::make_shared<const std::vector<EntryObserver>>(it->second.observers);
        publishFastHook(address, &it->second);
        return true;
    }

    bool FunctionHooks::replace(uint32_t address, std::string name, GuestFunction implementation, ReplacementStatus status, std::string reason)
    {
        if (!m_runtime)
        {
            return false;
        }
        std::lock_guard<std::mutex> lock(g_mutex);
        GuestFunction original = m_runtime->lookupFunction(address);
        auto &hook = g_hooks[address];
        if (!hook.original)
        {
            hook.original = original;
        }
        hook.binding = FunctionBinding{address, std::move(name), status, std::move(reason)};
        publishFastHook(address, &hook);
        return m_runtime->replaceFunction(address, implementation);
    }

    void FunctionHooks::observedTrampoline(uint8_t *rdram, R5900Context *ctx, PS2Runtime *runtime)
    {
        const uint32_t address = ctx->pc;
        if (const Hook *fastHook = lookupFastHook(address))
        {
            const auto *obsList = fastHook->snapshot.get();
            if (obsList)
            {
                for (const auto &observer : *obsList)
                    observer(rdram, ctx, runtime);
            }
            fastHook->original(rdram, ctx, runtime);
            return;
        }
        GuestFunction original = nullptr;
        std::shared_ptr<const std::vector<EntryObserver>> snapshot;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            const auto it = g_hooks.find(address);
            if (it == g_hooks.end())
            {
                SOTC_ERROR(Hook, "trampoline entered with unknown pc 0x" << std::hex << address);
                runtime->requestStop();
                return;
            }
            original = it->second.original;
            snapshot = it->second.snapshot;
        }
        if (snapshot)
        {
            for (const auto &observer : *snapshot)
            {
                observer(rdram, ctx, runtime);
            }
        }
        original(rdram, ctx, runtime);
    }

    void FunctionHooks::logBindings() const
    {
        std::map<uint32_t, FunctionBinding> sorted;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            for (const auto &[address, hook] : g_hooks)
            {
                sorted.emplace(address, hook.binding);
            }
        }
        for (const auto &[address, binding] : sorted)
        {
            SOTC_INFO(Hook, "0x" << std::hex << std::setw(8) << std::setfill('0') << address << std::dec << " "
                                  << binding.name << " [" << statusName(binding.status) << "] " << binding.reason);
        }
    }
}
