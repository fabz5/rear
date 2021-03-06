#
# Prepare for the BACKUP=ZYPPER method.
#

# Try to care about possible errors
# see https://github.com/rear/rear/wiki/Coding-Style
set -e -u -o pipefail

# What files and programs need to be included in the ReaR recovery system.
# Use "${ARRAY[@]:-}" to avoid unbound variable "${ARRAY[@]}" when ARRAY=():
COPY_AS_IS=( "${COPY_AS_IS[@]:-}" "${COPY_AS_IS_ZYPPER[@]:-}" )
COPY_AS_IS_EXCLUDE=( "${COPY_AS_IS_EXCLUDE[@]:-}" "${COPY_AS_IS_EXCLUDE_ZYPPER[@]:-}" )
REQUIRED_PROGS=( "${REQUIRED_PROGS[@]:-}" "${REQUIRED_PROGS_ZYPPER[@]:-}" )
PROGS=( "${PROGS[@]:-}" "${PROGS_ZYPPER[@]:-}" )

# RPM packages data that need to be included in the ReaR recovery system:
LogPrint "Determining RPM packages data for ZYPPER..."

# Create the directory where data for BACKUP=ZYPPER gets stored
# below $VAR_DIR because the whole $VAR_DIR gets automatically
# copied into the ReaR recovery system so that this way the data
# will be automatically available for "rear recover":
local zypper_backup_dir=$VAR_DIR/backup/$BACKUP
test -d $zypper_backup_dir || mkdir $verbose -p -m 755 $zypper_backup_dir

# Determine all installed RPM packages:
rpm --query --all --last >$zypper_backup_dir/installed_RPMs

# Determine which of the installed RPM packages
# are not required by other installed RPM packages.
# Those independently installed RPM packages are those that
# either are intentionally installed by the admin
# or got unintentionally installed via recommended by other RPMs
# or are no longer required (orphans) after other RPMs had been removed:
cat /dev/null >$zypper_backup_dir/independent_RPMs
local rpm_package=""
for rpm_package in $( cut -d ' ' -f1 $zypper_backup_dir/installed_RPMs ) ; do
    # rpm_package is of the form name-version-release.architecture
    rpm_package_name_version=${rpm_package%-*}
    rpm_package_name=${rpm_package_name_version%-*}
    # The only reliably working way how to find out if an installed RPM package
    # is needed by another installed RPM package is to test if it can be erased.
    # In particular regarding "rpm -q --whatrequires" versus "rpm -e --test" see
    # https://lists.opensuse.org/opensuse-de/2011-11/msg00076.html
    # that reads (excerpt):
    # "rpm -q --whatrequires <something>" does not show all package dependencies because
    # this shows only the dependencies regarding the exact RPM capability <something>.
    # Only "rpm -e --test <package>" shows you all other packages which depend on package.
    rpm --erase --test $rpm_package &>/dev/null && echo "$rpm_package" >>$zypper_backup_dir/independent_RPMs
done

LogPrint "Wrote RPM packages data for ZYPPER to $zypper_backup_dir"

# Restore the ReaR default bash flags and options (see usr/sbin/rear):
apply_bash_flags_and_options_commands "$DEFAULT_BASH_FLAGS_AND_OPTIONS_COMMANDS"

