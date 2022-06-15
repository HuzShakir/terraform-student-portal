const AWS = require("aws-sdk");
const { default: jwtDecode } = require("jwt-decode");
AWS.config.update({
  region: process.env.REGION, 
});
const cognitoIdp = new AWS.CognitoIdentityServiceProvider();
const UserPoolId=process.env.USER_POOL_ID
function auth (req,res,next) {
  try{
    var header=req.headers.authorization.split(' ')[1]
    var user=jwtDecode(header)
    req.sub=user.sub
    req.userGroup=user['cognito:groups'].includes('SuperAdmin')?"SuperAdmin":user['cognito:groups'].includes('Faculty')?"Faculty":"Student"
    next()

  }
  catch{
    res.status(500).send("Header is not valid")
  }
}

function protect(req,res,next){
  if (req.userGroup=='Student'){
    res.send("Unauthorized User")
  }
  else{
    next()
  }
}

function admin(req,res,next){
  if (req.userGroup!='SuperAdmin'){
    res.send("Unauthorized User")
  }
  else{
    next()
  }
}

function updateUser(params){
  return cognitoIdp.adminUpdateUserAttributes({
    UserAttributes: [
      {
        Name: 'email',
        Value: params.email
      },
      {
        Name: "custom:Department" ,
        Value: params.Department,
      },
      {
        Name: "custom:ClassNo" ,
        Value: params.ClassNo,
      },
      {
        Name: 'email_verified',
        Value: 'true'
      },
      // {
      //   Name: 'username',
      //   Value: params.username
      // }
    ],
    UserPoolId: UserPoolId,
    Username: params.username
  },).promise()
}

function adminAddUserToGroup({ username, groupName }) {
  const params = {
    GroupName: groupName,
    UserPoolId: UserPoolId,
    Username: username,
  };

  return cognitoIdp.adminAddUserToGroup(params).promise();
}

async function createUser(body){
  var params={
    UserPoolId: UserPoolId ,
    Username: body.username ,
    ForceAliasCreation: true,
    // MessageAction: "SUPPRESS",
    TemporaryPassword: "Abcd123$",
    DesiredDeliveryMediums: ["EMAIL"],
    UserAttributes: [
      {
        Name: "email" ,
        Value: body.email,
      },
      {
        Name: 'email_verified',
        Value: 'true'
      },
    ],
  }
  body.groupName=="Student" && params.UserAttributes.push({
    Name: "custom:Department" ,
    Value: body.Department,
  },
{
  Name: "custom:ClassNo" ,
  Value: body.ClassNo,
})  
  return cognitoIdp.adminCreateUser(params).promise()
}

async function getStudents(){
  return cognitoIdp.listUsersInGroup({UserPoolId:UserPoolId,GroupName:'Student'}).promise()
}

async function getFaculties(){
  return cognitoIdp.listUsersInGroup({UserPoolId:UserPoolId,GroupName:'Faculty'}).promise()
}

module.exports = { adminAddUserToGroup ,createUser,updateUser,auth,protect,admin,getFaculties,getStudents};
