const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const { Twilio } = require('twilio');

const app = express();
const PORT = 3000;

// Connect to MongoDB
mongoose.connect('mongodb+srv://muganekihuro:Kihuro14036@cluster0.orq6mfp.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0', {

});
const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', () => console.log('Connected to MongoDB'));

// Define schema and model for data
const DataSchema = new mongoose.Schema({
  soil_moisture: Number,
  timestamp: { type: Date, default: Date.now }
});
const DataModel = mongoose.model('Data', DataSchema);

// Define schema and model for users
const UserSchema = new mongoose.Schema({
  username: String,
  password: String,
  name: String,
  email: String,
  address: String,
  contact: String
});
const UserModel = mongoose.model('User', UserSchema);

// Middleware
app.use(bodyParser.json());

// Create a Twilio client instance
const twilioClient = new Twilio('AC64f30b061bd65ddb6d2886d906120b0e', 'd6d64e51dfe72e821f9177ee465e53ba');

// Function to send SMS using Twilio
function sendSMS(message) {
    twilioClient.messages
        .create({
            body: message,
            from: '+13607039976', // Replace with your Twilio phone number
            to: '+254796153254' // Replace with recipient phone number
        })
        .then(message => console.log(`SMS sent: ${message.sid}`))
        .catch(error => console.error('Error sending SMS:', error));
}

// Route to retrieve the latest soil moisture data
app.get('/data/latest', (req, res) => {
  DataModel.findOne().sort({ timestamp: -1 }).exec()
    .then(data => {
      if (data) {
        const { soil_moisture, timestamp } = data;
        res.json({ soil_moisture, timestamp });
      } else {
        res.status(404).json({ message: 'No data found' });
      }
    })
    .catch(err => {
      console.error('Error retrieving data:', err);
      res.sendStatus(500);
    });
});

// Route to retrieve historical soil moisture data
app.get('/data/historical', (req, res) => {
  // Fetch data for the last 24 hours (for example)
  const twentyFourHoursAgo = new Date();
  twentyFourHoursAgo.setDate(twentyFourHoursAgo.getDate() - 1); // Subtract 1 day
  DataModel.find({ timestamp: { $gte: twentyFourHoursAgo } }).sort({ timestamp: 1 }).exec()
    .then(data => {
      if (data) {
        const historicalData = data.map(item => ({
          soil_moisture: item.soil_moisture,
          timestamp: item.timestamp
        }));
        res.json(historicalData);
      } else {
        res.status(404).json({ message: 'No historical data found' });
      }
    })
    .catch(err => {
      console.error('Error retrieving historical data:', err);
      res.sendStatus(500);
    });
});

// Route to retrieve user account details
app.get('/users/:username', (req, res) => {
  const { username } = req.params;

  UserModel.findOne({ username })
    .then(user => {
      if (user) {
        res.status(200).json(user);
      } else {
        res.status(404).json({ message: 'User not found' });
      }
    })
    .catch(err => {
      console.error('Error retrieving user:', err);
      res.status(500).json({ message: 'Internal server error' });
    });
});

// Route to handle user registration
app.post('/users/register', (req, res) => {
  const { username, password, name, email, address, contact } = req.body;
  
  // Check if username already exists
  UserModel.findOne({ username })
    .then(user => {
      if (user) {
        res.status(400).json({ message: 'Username already exists' });
      } else {
        // Create a new user document
        const newUser = new UserModel({ username, password, name, email, address, contact });
        return newUser.save();
      }
    })
    .then(() => {
      console.log('User registered successfully');
      res.sendStatus(200);
    })
    .catch(err => {
      console.error('Error registering user:', err);
      res.sendStatus(500);
    });
});

// Route to handle user login
app.post('/users/login', (req, res) => {
  const { username, password } = req.body;

  // Check if user exists and password matches
  UserModel.findOne({ username, password })
    .then(user => {
      if (user) {
        res.status(200).json({ message: 'Login successful', user });
      } else {
        res.status(401).json({ message: 'Invalid username or password' });
      }
    })
    .catch(err => {
      console.error('Error logging in:', err);
      res.status(500).json({ message: 'Internal server error' });
    });
});

// Route to handle incoming data from Arduino device
app.post('/data', (req, res) => {
  const { soil_moisture } = req.body;

  // Save data to MongoDB
  const newData
  = new DataModel({
    soil_moisture,
    timestamp: new Date() // Set timestamp to current date and time
  });

  newData.save()
    .then(() => {
      console.log('Data saved successfully');

      // Send back the saved soil moisture value in the response
      res.json({ soil_moisture });
    })
    .catch(err => {
      console.error('Error saving data:', err);
      res.sendStatus(500);
    });
});

// Route to handle pump state updates
app.post('/pump', (req, res) => {
  const { pump_state } = req.body;

  // Check pump state and send SMS accordingly
  if (pump_state === 'activated') {
      sendSMS(`Pump activated!`);
  } else if (pump_state === 'deactivated') {
      sendSMS(`Pump deactivated!`);
  }

  res.sendStatus(200); // Respond with success status
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});