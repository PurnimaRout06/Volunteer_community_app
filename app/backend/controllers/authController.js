// controllers/authController.js
// ─────────────────────────────────────────────────────────────────────────────
// Handles user registration, login, and Google OAuth sign-in.
// ─────────────────────────────────────────────────────────────────────────────

const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { OAuth2Client } = require("google-auth-library");
const User = require("../models/User");

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ─── Helper: Generate a signed JWT for a user ────────────────────────────────
function generateToken(user) {
  return jwt.sign(
    { id: user._id, email: user.email, username: user.username },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );
}

// ─── Helper: Return safe user object (no password) ───────────────────────────
function safeUser(user) {
  return {
    id: user._id,
    username: user.username,
    email: user.email,
    avatarUrl: user.avatarUrl,
    points: user.points,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/signup
// Register a new user with email and password.
// ─────────────────────────────────────────────────────────────────────────────
async function signup(req, res) {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: "username, email, and password are required." });
    }

    // Check if email is already taken
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ error: "An account with this email already exists." });
    }

    // Hash password before saving — never store plain text
    const hashedPassword = await bcrypt.hash(password, 12);

    const user = await User.create({ username, email, password: hashedPassword });
    const token = generateToken(user);

    return res.status(201).json({ message: "Account created successfully.", token, user: safeUser(user) });
  } catch (err) {
    console.error("Signup error:", err);
    return res.status(500).json({ error: "Server error during signup." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/login
// Log in with email and password.
// ─────────────────────────────────────────────────────────────────────────────
async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required." });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: "Invalid email or password." });
    }

    // Guard: account was created with Google OAuth
    if (!user.password) {
      return res.status(400).json({ error: "This account uses Google Sign-In. Please log in with Google." });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: "Invalid email or password." });
    }

    const token = generateToken(user);
    return res.status(200).json({ message: "Login successful.", token, user: safeUser(user) });
  } catch (err) {
    console.error("Login error:", err);
    return res.status(500).json({ error: "Server error during login." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/google
// Sign in or register using a Google ID token from the mobile app.
// ─────────────────────────────────────────────────────────────────────────────
async function googleLogin(req, res) {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: "Google ID token is required." });
    }

    // Verify token with Google
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const { sub: googleId, email, name, picture } = ticket.getPayload();

    // Find existing user by Google ID or email
    let user = await User.findOne({ $or: [{ googleId }, { email }] });

    if (!user) {
      // First-time Google login — create account automatically
      user = await User.create({ username: name, email, googleId, avatarUrl: picture });
    } else if (!user.googleId) {
      // Link Google ID to an existing email/password account
      user.googleId = googleId;
      user.avatarUrl = picture;
      await user.save();
    }

    const token = generateToken(user);
    return res.status(200).json({ message: "Google login successful.", token, user: safeUser(user) });
  } catch (err) {
    console.error("Google login error:", err);
    return res.status(500).json({ error: "Google authentication failed." });
  }
}

module.exports = { signup, login, googleLogin };
