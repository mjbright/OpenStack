
# Script to run nova quota tests under DevStack

# Change to nova dir:
cd /opt/stack/nova/

# Run *all* tests under Python 2.7:
#time tox -epy27

# Extract list of compute_api tests, then extract exceed(quota) tests:
testr list-tests compute_api > compute-api.tests
grep -i exceed compute-api.tests  > compute-api-quota.tests

# Run list of quota tests:
python -m testtools.run discover --load-list compute-api-quota.tests


