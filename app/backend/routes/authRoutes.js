// routes/authRoutes.js
const express = require("express");
const router = express.Router();
const { signup, login, googleLogin } = require("../controllers/authController");

// POST /api/auth/signup  — Register with email + password
router.post("/signup", signup);

// POST /api/auth/login   — Login with email + password
router.post("/login", login);

// POST /api/auth/google  — Login or register with Google ID token
router.post("/google", googleLogin);

module.exports = router;
