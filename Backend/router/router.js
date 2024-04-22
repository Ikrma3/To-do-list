const express = require('express');
const router = express.Router();
const taskController = require('../controller/controller');
//// Route to create a new task
router.post('/tasks', taskController.createTask);
// Route to get all tasks
router.get('/tasks/:userId', taskController.getTaskDataForDisplay);
// Route to get details of a specific task by ID
router.get('/tasks/:id', taskController.getTaskDetailsById);
// Route to update a task by ID
router.put('/tasks/:id', taskController.updateTask);
// Route to delete a task by ID
router.delete('/tasks/:id', taskController.deleteTask);
router.post('/signup', taskController.signup);
router.post('/login', taskController.login);


module.exports = router;
