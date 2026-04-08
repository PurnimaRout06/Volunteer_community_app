// server.js
// ─────────────────────────────────────────────────────────────────────────────
// EventApp Backend — Main Entry Point
// Run with: node server.js  (or: npm run dev  for auto-reload with nodemon)
// ─────────────────────────────────────────────────────────────────────────────

require("dotenv").config(); // Load .env variables before anything else

const express        = require("express");
const cors           = require("cors");
const { connectDB }  = require("./config/database");

// ── Import Routes ─────────────────────────────────────────────────────────────
const authRoutes         = require("./routes/authRoutes");
const eventRoutes        = require("./routes/eventRoutes");
const userRoutes         = require("./routes/userRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const chatRoutes         = require("./routes/chatRoutes");

// ── App Setup ─────────────────────────────────────────────────────────────────
const app  = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());                              // Allow mobile app to call this API
app.use(express.json());                      // Parse JSON request bodies
app.use(express.urlencoded({ extended: true }));

// ── Mount Routes ──────────────────────────────────────────────────────────────
app.use("/api/auth",          authRoutes);         // Public — no JWT needed
app.use("/api/events",        eventRoutes);        // Protected
app.use("/api/users",         userRoutes);         // Protected
app.use("/api/notifications", notificationRoutes); // Protected
app.use("/api/chats",         chatRoutes);         // Protected

// ── Health Check ──────────────────────────────────────────────────────────────
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", message: "EventApp backend is running." });
});

// ── 404 Handler ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found.` });
});

// ── Global Error Handler ──────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "An unexpected server error occurred." });
});

// ── Connect to MongoDB, then Start Server ─────────────────────────────────────
// We connect to MongoDB first — the server only starts if the DB is reachable.
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`\n🚀 EventApp backend running at http://localhost:${PORT}`);
    console.log(`   Environment : ${process.env.NODE_ENV || "development"}`);
    console.log(`   Database    : MongoDB`);
    console.log(`   Health check: http://localhost:${PORT}/health\n`);
  });
});
