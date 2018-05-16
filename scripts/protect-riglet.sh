if [[ $# -lt 3 ]] ; then
  echo "Usage: protect-riglet <prefix> <region> <enable|disable|list>"
  echo "('list' just shows the stacks that would be impacted by 'enable' or 'disable')"
  exit 0
fi

prefix=${1}
region=${2}
mode=${3}

list_stacks() {
  aws cloudformation list-stacks --stack-status CREATE_COMPLETE UPDATE_COMPLETE --region ${2}  | \
    jq '.StackSummaries[] | select(.StackName | startswith('\"${1}\"')) | select(has("ParentId") | not) | select(.StackName | index("-app-") | not) | .StackName' | sed 's/\"//g'
}

for stack in $(list_stacks ${prefix} ${region}); do
  case "${mode}" in
    enable) echo "Enabling protection: ${stack} "; aws cloudformation update-termination-protection --enable-termination-protection --stack-name $stack --region ${region};
            ;;
    disable) echo "Disabling protection ${stack}"; aws cloudformation update-termination-protection --no-enable-termination-protection --stack-name $stack --region ${region};
             ;;
    list) echo ${stack}
         ;;
    *) echo "Invalid mode: ${mode} for ${stack} at ${region}"
  esac
done
