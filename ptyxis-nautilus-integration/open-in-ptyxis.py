import shlex
import subprocess
from typing import List

from gi.repository import GObject, Nautilus


class PtyxisMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def on_launch_ptyxis(self, _, info: Nautilus.FileInfo):
        location = info.get_location()
        if not location:
            return

        target_path = location.get_path()
        if not target_path:
            return

        command = (
            f"flatpak run app.devsuite.Ptyxis --tab --working-directory={shlex.quote(target_path)}"
        )
        print(command)
        subprocess.Popen(shlex.split(command), start_new_session=True)

    def get_file_items(
        self,
        files: List[Nautilus.FileInfo],
    ) -> List[Nautilus.MenuItem]:
        if len(files) != 1:
            return []

        file = files[0]
        if not file.is_directory():
            return []

        menu_item = Nautilus.MenuItem(
            name="PtyxisMenuProvider::OpenItem", label="Open in Ptyxis"
        )
        menu_item.connect("activate", self.on_launch_ptyxis, file)

        return [menu_item]

    def get_background_items(
        self, current_folder: Nautilus.FileInfo
    ) -> List[Nautilus.MenuItem]:
        menu_item = Nautilus.MenuItem(
            name="PtyxisMenuProvider::OpenBackground", label="Open in Ptyxis"
        )
        menu_item.connect("activate", self.on_launch_ptyxis, current_folder)

        return [menu_item]
