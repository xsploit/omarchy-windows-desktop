# Windows Explorer-style right-click items for Files (Nautilus).
#
#   Open in Terminal   — on a folder, or on the folder background
#   Copy as path       — absolute path(s) to the clipboard, one per line,
#                        the way Explorer's Shift+right-click does it
#
# Loaded by nautilus-python from ~/.local/share/nautilus-python/extensions.
import os
import shutil

from gi import require_version

require_version("Nautilus", "4.1")

from gi.repository import GObject, Gio, Nautilus


class WindowsContextMenu(GObject.GObject, Nautilus.MenuProvider):
    def _path(self, file):
        location = file.get_location()
        return location.get_path() if location else None

    def _open_terminal(self, menu, directory):
        # xdg-terminal-exec honours the user's default terminal; foot is that
        # here, and -D sets its working directory.
        foot = shutil.which("foot")
        if foot:
            Gio.Subprocess.new([foot, "-D", directory], Gio.SubprocessFlags.NONE)
            return
        term = shutil.which("xdg-terminal-exec")
        if term:
            Gio.Subprocess.new([term], Gio.SubprocessFlags.NONE)

    def _copy_paths(self, menu, paths):
        wl_copy = shutil.which("wl-copy")
        if not wl_copy:
            return
        proc = Gio.Subprocess.new([wl_copy], Gio.SubprocessFlags.STDIN_PIPE)
        proc.communicate_utf8("\n".join(paths), None)

    def _terminal_item(self, directory, suffix):
        item = Nautilus.MenuItem(
            name="WindowsContext::open_terminal_" + suffix,
            label="Open in Terminal",
            icon="utilities-terminal",
        )
        item.connect("activate", self._open_terminal, directory)
        return item

    def get_file_items(self, files):
        paths = [p for p in (self._path(f) for f in files) if p]
        if not paths:
            return []
        items = []
        if len(files) == 1 and files[0].is_directory():
            items.append(self._terminal_item(paths[0], "file"))
        copy = Nautilus.MenuItem(
            name="WindowsContext::copy_as_path",
            label="Copy as path",
            icon="edit-copy",
        )
        copy.connect("activate", self._copy_paths, paths)
        items.append(copy)
        return items

    def get_background_items(self, current_folder):
        directory = self._path(current_folder)
        if not directory or not os.path.isdir(directory):
            return []
        return [self._terminal_item(directory, "background")]
