const express = require('express');
const task_router=require('./router/router');
const mongoose = require("mongoose");
const cors = require('cors');
const { mongo_db } = require('./token.env')
//const shop_route = require('./router/shop_router');
const app = express();
app.use(express.json());
app.use(cors());
const port = process.env.PORT || 4000;
app.use('/', task_router);
mongoose.connect(mongo_db)
    .then(() => {
        console.log("Connected to MongoDB");
        app.listen(port, () => {
            console.log("Server running on port", port);
        });
    })
    .catch(error => {
        console.error("Error connecting to MongoDB:", error);
    });
    console.error();
