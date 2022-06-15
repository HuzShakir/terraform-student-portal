const AWS = require("aws-sdk");
const express = require("express");
const serverless = require("serverless-http");
const { 
  auth,
  createUser,
  adminAddUserToGroup,
  protect,
  getFaculties,
  admin,
  updateUser,
  getStudents,
} = require("./lambda");
const cors = require("cors");
const app = express();
AWS.config.update({
  region: "ap-south-1", //Here add you region
});
var ddb = new AWS.DynamoDB({ apiVersion: "2012-10-08" });
const USERS_TABLE = process.env.USERS_TABLE;
const dynamoDbClient = new AWS.DynamoDB.DocumentClient();

app.use(express.json());

app.use(function (req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  next();
});

app.use(cors());

app.use(auth);

app.post("/", protect,function (req, res) {
  console.log(req.userGroup);
  body = req.body;
  createUser(body)
    .then((data) => {
      const attributes = data.User.Attributes;
      console.log(req.userGroup);
      adminAddUserToGroup({
        groupName: body.groupName,
        username: data.User.Username,
      })
        .then(async  (data) => {
          console.log(data);
          if (body.groupName != "Student") {
            res.send(`${body.groupName} has been created successfully`);
          } else {
            console.log(attributes);
            let ddbParams = {
              Item: {
                id: { S: attributes[0].Value },
                sk: { S: "User Attributes" },
                __typename: { S: "User" },
                username: { S: body.username },
                ClassNo: { S: attributes[4].Value },
                Department: { S: attributes[2].Value },
                email: { S: attributes[3].Value },
                createdAt: { S: new Date().toISOString() },
              },
              TableName: USERS_TABLE,
            };
    
            await ddb.putItem(ddbParams).promise();
            res.send("Student has been created successfully");
          }
        })
        .catch((err) => console.log(err));
    })
    .catch((err) => {
      console.log(err);
      res.json(err);
    });
});

app.post("/student/:studentId", protect, function (req, res) {
  const body = req.body;
  updateUser(body)
    .then((data) => {
      const params = {
        Key: { id: req.params.studentId, sk: "User Attributes" },
        TableName: USERS_TABLE,
        UpdateExpression: "set email = :p, Department = :r, ClassNo = :q",
        ExpressionAttributeValues: {
          ":p": body.email,
          ":r": body.Department,
          ":q": body.ClassNo,
        },
      };
      dynamoDbClient
        .update(params)
        .promise()
        .then((data) => {
          console.log(data)
          res.send("Student credentials has been updated successfully")
        })
        .catch((err) => console.log(err));
    })
    .catch((err) => {
      console.log(err + "Error aavyo che");
      res.status(403).json(err);
    });
});

app.get("/student/:studentId", function (req, res) {
  if (req.sub !== req.params.studentId && req.userGroup === "Student") {
    res.status(401).send("Unauthorized User");
  }
  var params = {
    TableName: USERS_TABLE,
    KeyConditionExpression: "id = :hkey",
    ExpressionAttributeValues: {
      ":hkey": req.params.studentId,
    },
  };
  dynamoDbClient.query(params, function (err, data) {
    if (err) res.json(err);
    else res.json(data.Items);
  });
});

app.get("/faculties", function (req, res) {
  getFaculties()
    .then((data) => res.json(data.Users))
    .catch((err) => res.json(err));
});

app.delete("/studentdetails/:studentId", protect, function (req, res) {
  console.log("yello");
  dynamoDbClient
    .delete({
      Key: {
        id: req.params.studentId,
        sk: req.body.sk,
      },
      TableName: USERS_TABLE,
    })
    .promise()
    .then((data) => res.json(data))
    .catch((err) => res.json(err));
});

app.post("/studentdetails/:studentId", protect, function (req, res) {
  var body = req.body;
  console.log(body);
  let ddbParams = {
    Item: {
      id:  req.params.studentId ,
      sk:  body.Name ,
      value: body.data,
    },
    TableName: USERS_TABLE,
  };

  dynamoDbClient
    .put(ddbParams)
    .promise()
    .then((data) => {
      res.send("Details has been set successfully");
    })
    .catch((err) => console.log(err));
});

app.get("/students", protect, function (req, res) {
  getStudents()
    .then((data) => res.json(data.Users))
    .catch((err) => res.json(err));
});

app.use((req, res, next) => {
  return res.status(404).json({
    error: "Not Found",
  });
});

// app.listen(5000, () => {
//   console.log("Server is running on http://127.0.0.1:5000");
// });
module.exports.handler = serverless(app);
