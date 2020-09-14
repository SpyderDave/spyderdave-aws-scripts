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
    ORGUNIT=$2
    shift # past argument
    shift # past value
    ;;
    -O|--output-file)
    OUTFILE=$2
    shift
    shift
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
if [[ -z $OUTFILE ]]
then
   DATESTAMP=$(date "+%Y%m%d%H%M%S")
   OUTFILE=accounts.$DATESTAMP
fi
echo "Results will be written to $OUTFILE"

echo "Assuming Role in the Master Account - to gain access to AWS Organizations"
temp_role=$(aws sts assume-role --role-arn ${ROLEARN} --role-session-name organizations-securityhub)
export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq .Credentials.SessionToken | xargs)
#echo "AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID
#echo "AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY
#echo "AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN

echo "Obtaining the RootId"
ROOTID=$(aws organizations list-roots --query 'Roots[?Name.Value==Root].Id' --output text)
echo "My RootId=$ROOTID"

echo "Listing Children:"
if [[ $ORGUNIT == "Root" ]]
then
  ORGUNIT=$ROOTID
  aws organizations list-children --parent-id ${ORGUNIT} --child-type ${CHILDTYPE}
else
  echo "OU passed - finding it....."
  OUIDS=$(aws organizations list-children --parent-id $ROOTID --child-type ORGANIZATIONAL_UNIT | jq -r ".Children[] | {id: .Id} | .id ")
  # loop through the ou list to find the one we want
  for id in $OUIDS
  do
    echo "Checking $id to see if its name matches...."
    MyName=$(aws organizations describe-organizational-unit --organizational-unit-id "$id" --output text --query 'OrganizationalUnit.Name')
    if [[ "$MyName" == "$ORGUNIT" ]]
    then
      echo "Found matching OU Named: $MyName with Id: $id"
#      aws organizations list-accounts-for-parent --parent-id $id  --output text --query 'Accounts[*].{Email:Email,ID:Id}' | sed -E 's/\s+/,/g' >>$OUTFILE
       ID=$(aws organizations list-accounts-for-parent --parent-id $id --output text --query 'Accounts[*].Id')
       EMAIL=$(aws organizations list-accounts-for-parent --parent-id $id --output text --query 'Accounts[*].Email')
       echo "$ID,$EMAIL"
    else
      echo "Skipping OU Named: $MyName"
    fi
  done
fi