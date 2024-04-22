// Import Mongoose
const mongoose = require('mongoose');

// Define user schema
const userSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: true
  },
  lastName: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    unique: true // Ensures that each email is unique in the database
  },
  password: {
    type: String,
    required: true
  }
});

// Create and export User model
const User = mongoose.model('User', userSchema);
module.exports = User;
