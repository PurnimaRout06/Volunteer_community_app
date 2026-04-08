// routes/userRoutes.js
const express = require("express");
const router = express.Router();
const { getProfile, getAttendedEvents, getOrganizedEvents, registerForEvent } = require("../controllers/userController");
const { authenticateToken } = require("../middleware/auth");

router.use(authenticateToken);

// GET  /api/users/profile             — Fetch profile (username, email, points)
router.get("/profile", getProfile);

// GET  /api/users/attended-events     — Events the user attended
router.get("/attended-events", getAttendedEvents);

// GET  /api/users/organized-events    — Events the user organized
router.get("/organized-events", getOrganizedEvents);

// POST /api/users/register-event/:eventId — Register for an event
router.post("/register-event/:eventId", registerForEvent);

module.exports = router;
