const mongoose = require('mongoose');

async function fixTherapyDate() {
  try {
    await mongoose.connect('mongodb://localhost:27017/vitalink');
    
    const PatientProfile = mongoose.model('PatientProfile', new mongoose.Schema({}, {strict: false}));
    
    // Set therapy start date to 2 weeks ago
    const twoWeeksAgo = new Date();
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
    
    const result = await PatientProfile.updateOne(
      { _id: new mongoose.Types.ObjectId('69787e65cafb22da6ebfce16') },
      { $set: { 'medical_config.therapy_start_date': twoWeeksAgo } }
    );
    
    console.log('Update result:', result);
    console.log('New therapy start date:', twoWeeksAgo);
    
    // Verify the update
    const patient = await PatientProfile.findById('69787e65cafb22da6ebfce16');
    console.log('Verified therapy_start_date:', patient.medical_config.therapy_start_date);
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

fixTherapyDate();
