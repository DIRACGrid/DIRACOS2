#!/bin/bash

# This script is used to test the binaries
# It just calls them with the --help flag,
# or -h, or without. Any of these should be working
# otherwise we consider it an issue

scriptsToTest=(mysql gfal-ls gfal-stat voms-proxy-init rrdtool);
rc=0

for script in "${scriptsToTest[@]}"; do
   # Try --help first
   if ! ${script} --help &>/dev/null; then
     # Try just -h
     if ! ${script} -h &>/dev/null; then
      # If it still fails, try with no options
       if ! ${script}  &>/dev/null; then
         # If it still fails, it fails...
         echo "${script} is not working";
         rc=1;
       fi
     fi
   fi
done

# Now some specific tests that do not behave like the other binaries

# For BDDI and ARC
if ! (ldapsearch --help 2>&1 >/dev/null | grep -q "usage: ldapsearch"); then
  echo "ldapsearch not working";
  rc=1;
fi

# For SSHComputingElement
if ! (ssh --help 2>&1 >/dev/null | grep -q "usage:"); then
  echo "ssh not working";
  rc=1;
fi

# For https://github.com/DIRACGrid/DIRACOS/issues/107
if ! (git --exec-path | grep "${DIRAC}"); then
  echo "git --exec-path does not contain ${DIRAC}";
  rc=1;
fi

# For singularity
if ! singularity version; then
  echo "singularity version not working";
  rc=1;
fi
if ! singularity build --force --sandbox hello-world docker://hello-world; then
  echo "singularity build not working";
  rc=1;
fi
if ! (singularity --verbose --debug run -u hello-world || (singularity --verbose --debug run -u hello-world 2>&1 | grep -E 'Failed to create user namespace: (Operation not permitted|Invalid argument)')); then
  echo "singularity run not working";
  rc=1;
fi

# For apptainer
if ! apptainer version; then
  echo "apptainer version not working";
  rc=1;
fi
if ! apptainer build --force --sandbox hello-world2 docker://hello-world; then
  echo "apptainer build not working";
  rc=1;
fi
if ! (apptainer --verbose --debug run -u hello-world2 || (apptainer --verbose --debug run -u hello-world2 2>&1 | grep -E 'Failed to create user namespace: (Operation not permitted|Invalid argument)')); then
  echo "apptainer run not working";
  rc=1;
fi

# For HTCondor
if ! condor_submit -help; then
  echo "condor_submit -help not working";
  rc=1;
fi
if ! condor_history -help; then
  echo "condor_history -help not working";
  rc=1;
fi
if ! condor_q -help; then
  echo "condor_q -help not working";
  rc=1;
fi
if ! condor_rm -help; then
  echo "condor_rm -help not working";
  rc=1;
fi
if ! condor_transfer_data -help; then
  echo "condor_transfer_data -help not working";
  rc=1;
fi

exit $rc
