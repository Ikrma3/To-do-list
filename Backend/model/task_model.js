// Import Mongoose
const mongoose = require('mongoose');

// Define task schema
const taskSchema = new mongoose.Schema({
  taskName: {
    type: String,
    required: true
  },
  taskDetails: {
    type: String,
    required: true
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high'], // Enumerated values for task status
    default: 'low' // Default status is 'pending'
  },
  deadline: {
    type: Date,
    required: true
  },
  order: {
    type: Number,
    required: true
  },
  userId: {
    type: String,
    required: true
  },
  taskStatus:{
    type:String,
    
  }
});

// Create and export Task model
const Task = mongoose.model('Task', taskSchema);
module.exports = Task;
