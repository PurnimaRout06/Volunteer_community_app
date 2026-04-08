// middleware/auth.js
// ─────────────────────────────────────────────────────────────────────────────
// JWT Authentication Middleware
// Protects routes that require the user to be logged in.
// Usage: add `authenticateToken` as middleware to any protected route.
// ─────────────────────────────────────────────────────────────────────────────

const jwt = require("jsonwebtoken");

/**
 * Middleware: Verify JWT token from the Authorization header.
 * Expects header format: "Authorization: Bearer <token>"
 * If valid, attaches the decoded user payload to req.user.
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];

  // The token comes after "Bearer "
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "Access denied. No token provided." });
  }

  try {
    // Verify token using our secret key
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, email, username }
    next();
  } catch (err) {
    return res.status(403).json({ error: "Invalid or expired token." });
  }
}

module.exports = { authenticateToken };
