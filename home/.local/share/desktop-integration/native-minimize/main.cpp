#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/managers/EventManager.hpp>
#include <hyprland/src/protocols/XDGShell.hpp>
#include <hyprland/src/xwayland/XSurface.hpp>
#include <unordered_map>
static std::unordered_map<uintptr_t, CHyprSignalListener> listeners;
static CHyprSignalListener opened, closed;
APICALL EXPORT std::string PLUGIN_API_VERSION() { return HYPRLAND_API_VERSION; }
static void attach(PHLWINDOW w) {
    auto key = reinterpret_cast<uintptr_t>(w.get());
    if (listeners.contains(key)) return;
    PHLWINDOWREF weak = w;
    auto changed = [weak] {
        auto w = weak.lock();
        if (!w) return;
        std::optional<bool> request;
        if (w->m_xdgSurface && w->m_xdgSurface->m_toplevel)
            request = w->m_xdgSurface->m_toplevel->m_state.requestsMinimize;
        else if (w->m_xwaylandSurface) {
            request = w->m_xwaylandSurface->m_state.requestsMinimize;
            w->m_xwaylandSurface->m_state.requestsMinimize.reset();
        }
        if (request.has_value())
            g_pEventManager->postEvent(SHyprIPCEvent{.event="minimized", .data=std::format("{:x},{}", reinterpret_cast<uintptr_t>(w.get()), *request ? 1 : 0)});
    };
    if (w->m_xdgSurface && w->m_xdgSurface->m_toplevel)
        listeners.emplace(key, w->m_xdgSurface->m_toplevel->m_events.stateChanged.listen(changed));
    else if (w->m_xwaylandSurface)
        listeners.emplace(key, w->m_xwaylandSurface->m_events.stateChanged.listen(changed));
}
APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    if (std::string(__hyprland_api_get_hash()) != std::string(__hyprland_api_get_client_hash()))
        throw std::runtime_error("Native minimize: Hyprland version mismatch");
    opened = Event::bus()->m_events.window.open.listen([](PHLWINDOW w) { attach(w); });
    closed = Event::bus()->m_events.window.close.listen([](PHLWINDOW w) { listeners.erase(reinterpret_cast<uintptr_t>(w.get())); });
    for (auto& w : Desktop::windowState()->windows()) if (w->m_isMapped) attach(w);
    return {"native-minimize", "Forward native minimize requests to the desktop window service", "Local desktop integration", "1.0"};
}
APICALL EXPORT void PLUGIN_EXIT() { opened.reset(); closed.reset(); listeners.clear(); }
