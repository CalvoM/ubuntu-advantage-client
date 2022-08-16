from typing import List

import mock

from uaclient.api.u.pro.security_status.packages.v1 import (
    _get_installed_packages,
)

M_PATH = "uaclient.api.u.pro.security_status.packages.v1"


class FakeVersion:
    def __init__(self, version, is_installed):
        self.version_ = version
        self.is_installed_ = is_installed

    @property
    def version(self):
        return self.version_

    @property
    def is_installed(self):
        return self.is_installed_


class FakePackage:
    def __init__(
        self, name: str, installed: bool, version: FakeVersion
    ) -> None:
        self.installed_ = installed
        self.name_ = name
        self.version = version

    @property
    def name(self):
        return self.name_

    @property
    def is_installed(self) -> bool:
        return self.installed_

    @property
    def versions(self) -> List:
        return [self.version]


class FakeCache:
    def __init__(self, packages):
        self.packages = packages

    def __iter__(self):
        for pkg in self.packages:
            yield pkg


@mock.patch(M_PATH + ".system.subp")
@mock.patch(M_PATH + ".Cache")
class TestPackageInstalledV1:
    def test_snap_packages_added(self, apt_cache, sys_subp, FakeConfig):
        apt_cache.return_value = []
        sys_subp.return_value = (
            "Name  Version Rev Tracking Publisher Notes\n"
            "helloworld 6.0.16 126 latest/stable dev1 -\n"
            "bare 1.0 5 latest/stable canonical** base\n"
            "canonical-livepatch 10.2.3 146 latest/stable canonical** -\n"
        ), ""
        result = _get_installed_packages(FakeConfig())
        assert (
            "helloworld\t6.0.16\nbare\t1.0\ncanonical-livepatch\t10.2.3\n"
            == result.manifest_data
        )

    def test_apt_packages_added(self, apt_cache, sys_subp, FakeConfig):
        sys_subp.return_value = "", ""
        cache = FakeCache(
            [
                FakePackage("one", True, FakeVersion("4:1.0.2", True)),
                FakePackage("three", False, FakeVersion("3.2", False)),
                FakePackage("two", True, FakeVersion("0.1.1", True)),
            ]
        )
        apt_cache.side_effect = [cache]

        result = _get_installed_packages(FakeConfig())
        assert "one\t4:1.0.2\ntwo\t0.1.1\n" == result.manifest_data

    def test_apt_snap_packages_added(self, apt_cache, sys_subp, FakeConfig):
        cache = FakeCache(
            [
                FakePackage("one", True, FakeVersion("4:1.0.2", True)),
                FakePackage("three", False, FakeVersion("3.2", False)),
                FakePackage("two", True, FakeVersion("0.1.1", True)),
            ]
        )
        sys_subp.return_value = (
            "Name  Version Rev Tracking Publisher Notes\n"
            "helloworld 6.0.16 126 latest/stable dev1 -\n"
            "bare 1.0 5 latest/stable canonical** base\n"
            "canonical-livepatch 10.2.3 146 latest/stable canonical** -\n"
        ), ""
        apt_cache.side_effect = [cache]
        result = _get_installed_packages(FakeConfig())
        assert (
            "helloworld\t6.0.16\nbare\t1.0\n"
            + "canonical-livepatch\t10.2.3\none\t4:1.0.2\ntwo\t0.1.1\n"
            == result.manifest_data
        )
