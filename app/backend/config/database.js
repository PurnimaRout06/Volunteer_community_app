// config/database.js
// ─────────────────────────────────────────────────────────────────────────────
// MongoDB connection using Mongoose.
// Mongoose is the most popular ODM (Object Document Mapper) for MongoDB in
// Node.js — it lets us define schemas and interact with the database using
// simple JavaScript objects instead of raw queries.
//
// How to use:
//   - Local: set MONGO_URI=mongodb://localhost:27017/eventapp in .env
//   - Atlas:  set MONGO_URI=mongodb+srv://<user>:<pass>@cluster.mongodb.net/eventapp
// ─────────────────────────────────────────────────────────────────────────────

const mongoose = require("mongoose");

/**
 * connectDB — call this once in server.js before starting the Express server.
 * Mongoose automatically handles reconnections if the connection drops.
 */
async function connectDB() {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`✅ MongoDB connected: ${conn.connection.host}`);
  } catch (err) {
    console.error("❌ MongoDB connection failed:", err.message);
    // Exit the process — the app cannot run without a database
    process.exit(1);
  }
}

module.exports = { connectDB };
