ROLEARN=arn:aws:iam::948143805254:role/thcp/privilegedservice/AWSFoundationsBootstrappingRole
temp_role=$(aws sts assume-role --role-arn ${ROLEARN} --role-session-name organizations-securityhub)
export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq .Credentials.SessionToken | xargs)
echo "AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID
echo "AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY
echo "AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN
ROOTID=$(aws organizations list-roots --query 'Roots[?Name.Value==Root].Id' --output text)
echo "My RootId=$ROOTID"

echo "Listing Children:"
aws organizations list-children --parent-id r-zayt --child-type ORGANIZATIONAL_UNIT
echo "Listing Accounts"
aws organizations list-accounts --output text --query 'Accounts[*].{ID:Id,Email:Email}' | sed -E 's/\s+/,/g'