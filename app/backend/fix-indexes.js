// fix-indexes.js
// Drop the problematic googleId unique index

require("dotenv").config();
const mongoose = require("mongoose");

async function fixIndexes() {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ Connected to MongoDB");

    // Drop the googleId unique index
    const collection = conn.connection.collection("users");
    await collection.dropIndex("googleId_1");
    console.log("✅ Dropped googleId_1 index");

    // Verify no other problematic indexes
    const indexes = await collection.getIndexes();
    console.log("📋 Current indexes:", Object.keys(indexes));

    console.log("✅ Index fix complete! Now restart the server.");
    process.exit(0);
  } catch (err) {
    console.error("❌ Error:", err.message);
    process.exit(1);
  }
}

fixIndexes();
