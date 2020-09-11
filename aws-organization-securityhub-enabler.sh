#!/bin/bash
#
# Assume Role
# Get list of accounts
# Write the list in CSV format to stdout (redirect as you see fit)

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
 
case $key in
    -r|--role)
    ROLEARN="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--orgunit)
    ORGUNIT="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Unknown Option"
    exit 9
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# TEMP - static role for testing.
ROLEARN=arn:aws:iam::948143805254:role/thcp/privilegedservice/AWSFoundationsBootstrappingRole
#
if [[ -z $ORGUNIT ]]
then 
  echo "Using Root OU"
  ORGUNIT=Root
  CHILDTYPE="ACCOUNT" 
else 
  echo "Using OU: ${ORGUNIT}"
  CHILDTYPE="ORGANIZATIONAL_UNIT"
fi 

echo "Assuming Role in the Master Account - to gain access to AWS Organizations"
temp_role=$(aws sts assume-role --role-arn ${ROLEARN} --role-session-name organizations-securityhub)
export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq .Credentials.SessionToken | xargs)
echo "AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID
echo "AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY
echo "AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN

echo "Obtaining the RootId"
ROOTID=$(aws organizations list-roots --query 'Roots[?Name.Value==Root].Id' --output text)
echo "My RootId=$ROOTID"

echo "Listing Children:"
if [[ ]]
aws organizations list-children --parent-id ${ORGUNIT} --child-type ${CHILDTYPE}

#echo "Listing Accounts"
#aws organizations list-accounts --output text --query 'Accounts[*].{ID:Id,Email:Email}' | sed -E 's/\s+/,/g'