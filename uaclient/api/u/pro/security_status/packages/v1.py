from apt import Cache  # type: ignore

from uaclient import system
from uaclient.api.api import APIEndpoint
from uaclient.api.data_types import AdditionalInfo
from uaclient.config import UAConfig
from uaclient.data_types import DataObject, Field, StringDataValue


class InstalledPackagesResults(DataObject, AdditionalInfo):
    fields = [
        Field("manifest_data", StringDataValue),
    ]

    def __init__(self, manifest_data: str):
        self.manifest_data = manifest_data


def get_installed_packages() -> InstalledPackagesResults:
    return _get_installed_packages(UAConfig())


def _get_installed_packages(cfg: UAConfig) -> InstalledPackagesResults:
    """Returns the status of installed packages (apt and snap packages)
    The returned dict has a 'package_name' key and the 'version' as the key.
    """
    cache = Cache()
    manifest = ""
    # get snap packages
    out, _ = system.subp(["snap", "list"])
    apps = out.splitlines()
    apps = apps[1:]
    for line in apps:
        pkg = line.split()
        manifest += "{app}\t{version}\n".format(app=pkg[0], version=pkg[1])

    # get apt packages
    for package in cache:
        if package.is_installed:
            version = [
                version.version
                for version in package.versions
                if version.is_installed
            ][0]
            manifest += "{app}\t{version}\n".format(
                app=package.name, version=version
            )

    return InstalledPackagesResults(manifest_data=manifest)


endpoint = APIEndpoint(
    version="v1",
    name="Packages",
    fn=_get_installed_packages,
    options_cls=None,
)
