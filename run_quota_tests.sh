
cd /opt/stack/nova/

#time tox -epy27

testr list-tests compute_api > compute-api.tests
grep -i exceed compute-api.tests  > compute-api-quota.tests

python -m testtools.run discover --load-list compute-api-quota.tests


