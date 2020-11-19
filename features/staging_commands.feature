@uses.config.contract_token_staging
Feature: Enable command behaviour when attached to an UA staging subscription

    @series.xenial
    Scenario: Attached enable CC EAL service in a xenial lxd container
        Given a `xenial` machine with ubuntu-advantage-tools installed
        When I attach `contract_token_staging` with sudo
        Then I verify that running `ua enable cc-eal` `as non-root` exits `1`
        And I will see the following on stderr:
            """
            This command must be run as root (try using sudo)
            """
        When I run `ua enable cc-eal --beta` with sudo
        Then I will see the following on stdout:
            """
            One moment, checking your subscription first
            GPG key '/usr/share/keyrings/ubuntu-cc-keyring.gpg' not found
            """

    @series.xenial
    @series.bionic
    @series.focal
    Scenario Outline: Attached enable esm-apps on a machine
        Given a `<release>` machine with ubuntu-advantage-tools installed
        When I attach `contract_token_staging` with sudo
        And I run `ua status --all` as non-root
        Then stdout matches regexp
        """
        esm-apps      yes                enabled            UA Apps: Extended Security Maintenance \(ESM\)
        """
        And I verify that running `apt update` `with sudo` exits `0`
        When I run `apt-cache policy` as non-root
        Then apt-cache policy for the following url has permission `500`
        """
        https://esm.staging.ubuntu.com/apps/ubuntu <release>-apps-updates/main amd64 Packages
        """
        And apt-cache policy for the following url has permission `500`
        """
        https://esm.staging.ubuntu.com/apps/ubuntu <release>-apps-security/main amd64 Packages
        """
        And I verify that running `apt update` `with sudo` exits `0`
        When I run `apt install -y <apps-pkg>` with sudo
        And I run `apt-cache policy <apps-pkg>` as non-root
        Then stdout matches regexp:
        """
        Version table:
        \s*\*\*\* .* 500
        \s*500 https://esm.staging.ubuntu.com/apps/ubuntu <release>-apps-security/main amd64 Packages
        """

        Examples: ubuntu release
           | release | apps-pkg |
           | bionic  | bundler  |
           | focal   | ant      |
           | trusty  | ant      |
           | xenial  | jq       |

    @series.bionic
    @uses.config.machine_type.lxd.vm
    Scenario Outline: Attached enable of vm-based services in an ubuntu lxd vm
        Given a `<release>` machine with ubuntu-advantage-tools installed
        When I attach `contract_token_staging` with sudo
        And I run `ua disable livepatch` with sudo
        And I run `apt-get install openssh-client openssh-server strongswan -y` with sudo
        When I run `ua enable fips --assume-yes --beta` with sudo
        Then stdout matches regexp:
            """
            Updating package lists
            Installing FIPS packages
            FIPS enabled
            A reboot is required to complete install
            """
        When I run `ua status --all` with sudo
        Then stdout matches regexp:
            """
            fips          yes                enabled
            """
        And I verify that running `apt update` `with sudo` exits `0`
        And I verify that running `grep Traceback /var/log/ubuntu-advantage.log` `with sudo` exits `1`
        And I verify that `openssh-server` is installed from apt source `<fips-apt-source>`
        And I verify that `openssh-client` is installed from apt source `<fips-apt-source>`
        And I verify that `strongswan` is installed from apt source `<fips-apt-source>`
        And I verify that `openssh-server-hmac` is installed from apt source `<fips-apt-source>`
        And I verify that `openssh-client-hmac` is installed from apt source `<fips-apt-source>`
        And I verify that `strongswan-hmac` is installed from apt source `<fips-apt-source>`
        When I reboot the `<release>` machine
        And  I run `uname -r` as non-root
        Then stdout matches regexp:
            """
            fips
            """
        When I run `cat /proc/sys/crypto/fips_enabled` with sudo
        Then I will see the following on stdout:
        """
        1
        """
        When I run `ua disable fips --assume-yes` with sudo
        Then stdout matches regexp:
            """
            Updating package lists
            A reboot is required to complete disable operation
            """
        When I reboot the `<release>` machine
        When I run `cat /proc/sys/crypto/fips_enabled` with sudo
        Then I will see the following on stdout:
        """
        0
        """
        And I verify that `openssh-server` installed version matches regexp `fips`
        And I verify that `openssh-client` installed version matches regexp `fips`
        And I verify that `strongswan` installed version matches regexp `fips`
        And I verify that `openssh-server-hmac` installed version matches regexp `fips`
        And I verify that `openssh-client-hmac` installed version matches regexp `fips`
        And I verify that `strongswan-hmac` installed version matches regexp `fips`

        Examples: ubuntu release
           | release | fips-apt-source |
           | xenial  | https://esm.staging.ubuntu.com/fips/ubuntu xenial/main |
           | bionic  | https://esm.staging.ubuntu.com/fips/ubuntu bionic/main |
