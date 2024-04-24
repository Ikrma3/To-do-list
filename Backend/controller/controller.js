const User=require("../model/User_model");
const Task=require("../model/task_model");
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
exports.createTask = async (req, res) => {
    const { taskName, taskDetails, deadline, priority, userId } = req.body;
    const taskStatus = 'pending';
    try {
      let order;
  
      // Find the count of tasks with higher priority
      const higherPriorityCount = await Task.countDocuments({ priority: { $gt: priority } });
  
      // If the priority is 'high', set the order to 1
      if (priority === 'high') {
        order = 1;
      }
      // If the priority is 'medium', set the order to the count of higher priority tasks + 1
      else if (priority === 'medium') {
        order = 2;
      }
      // If the priority is 'low', set the order to the count of all tasks + 1
      else {
        order = 3;
      }
  
      // Create the task in the database with the determined order and associated userId
      const newTask = await Task.create({
        taskName,
        taskDetails,
        taskStatus,
        deadline,
        priority,
        order,
        userId// Associate the task with the provided userId
      });
  
      // Send response with status 201 and success message
      res.status(201).json({ message: 'Task created successfully', task: newTask });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
};

  
  // Controller function to get task names and statuses
  exports.getTaskDataForDisplay = async (req, res) => {
    try {
      const userId = req.params.userId; // Assuming userId is passed as a route parameter
      // Fetch task IDs, names, statuses, priorities, and deadlines for the specified user
      const tasks = await Task.find({ userId }, { _id: 1, taskName: 1, taskStatus: 1, priority: 1, deadline: 1 })
                               .sort({ order: 1, deadline: 1 });
      res.status(200).json(tasks);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  };
exports.getTaskDetailsById = async (req, res) => {
  const taskId = req.params.id; // Assuming the task ID is passed as a route parameter
  try {
      // Fetch the task details from the database by ID
      const task = await Task.findById(taskId);

      // Check if the task exists
      if (!task) {
          return res.status(404).json({ error: 'Task not found' });
      }
      // Extract task details for display
      const { taskName, taskDetails, deadline } = task;

      // Send response with the task details
      res.status(200).json({ taskName, taskDetails, deadline });
  } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
  }
};
  exports.updateTask = async (req, res) => {
    const taskId = req.params.id; // Assuming the task ID is passed as a route parameter
    const { deadline} = req.body;
  
    try {
      // Fetch the task from the database by ID
      const task = await Task.findById(taskId);
  
      // Check if the task exists
      if (!task) {
        return res.status(404).json({ error: 'Task not found' });
      }
  
      // Update task details if provided
      // Update deadline if provided
      if (deadline) {
        task.deadline = deadline;
      }
      // Save the updated task to the database
      await task.save();
  
      // Send response indicating successful update
      res.status(200).json({ message: 'Task updated successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  };
  exports.updateStatus = async (req, res) => {
    console.log("Update call");
    const taskId = req.params.id; // Assuming the task ID is passed as a route parameter
    const { status } = req.body;
    console.log(status);
    try {
      // Fetch the task from the database by ID
      const task = await Task.findById(taskId);
  
      // Check if the task exists
      if (!task) {
        return res.status(404).json({ error: 'Task not found' });
      }
  
      // Update task details if provided
      // Update deadline if provided
      if (status) {
        task.taskStatus = status;
      }
      // Save the updated task to the database
      await task.save();
  
      // Send response indicating successful update
      res.status(200).json({ message: 'Task updated successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  };
  exports.deleteTask = async (req, res) => {
    const taskId = req.params.id; // Assuming the task ID is passed as a route parameter
  
    try {
      // Find the task by ID and delete it
      const deletedTask = await Task.findByIdAndDelete(taskId);
  
      // Check if the task exists
      if (!deletedTask) {
        return res.status(404).json({ error: 'Task not found' });
      }
  
      // Send response indicating successful deletion
      res.status(200).json({ message: 'Task deleted successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Server error' });
    }
  };
  exports.signup = async (req, res) => {
    const { firstName, lastName, email, password } = req.body;
  
    try {
      // Check if the email is already registered
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ message: 'Email already exists' });
      }
  
      // Hash the password
      const hashedPassword = await bcrypt.hash(password, 10);
  
      // Create a new user
      const newUser = await User.create({
        firstName,
        lastName,
        email,
        password: hashedPassword // Store the hashed password
      });
  
      res.status(201).json({ message: 'User created successfully', user: newUser });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Server error' });
    }
  };
  exports.login = async (req, res) => {
    console.log("Login");
   
    const { email, password } = req.body;
    console.log(email, password);
    const secretKey = crypto.randomBytes(32).toString('hex');
    try {
      // Check if the user exists
      const user = await User.findOne({ email });
      if (!user) {
        return res.status(401).json({ message: 'Invalid email or password' });
      }
  
      // Compare the provided password with the stored hashed password
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({ message: 'Invalid email or password' });
      }
  
      // Generate a JWT token for authentication
      const token = jwt.sign({ userId: user._id }, secretKey, { expiresIn: '1h' });
  
      // Send response with login success message, token, and user ID
      res.status(200).json({ message: 'Login successful', token, userId: user._id });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Server error' });
    }
};
