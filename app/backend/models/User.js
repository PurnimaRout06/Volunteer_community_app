// models/User.js
// ─────────────────────────────────────────────────────────────────────────────
// User schema — stores account info for all registered users.
// Supports both manual signup (email + password) and Google OAuth.
// ─────────────────────────────────────────────────────────────────────────────

const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: [true, "Username is required"],
      trim: true,
    },

    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,         // No two users can share the same email
      lowercase: true,
      trim: true,
    },

    // Null for Google OAuth users (they don't set a password)
    password: {
      type: String,
      default: null,
    },

    // Null for manual signup users
    googleId: {
      type: String,
      default: null,
      // Note: Not using unique: true here because sparse unique doesn't work well with
      // multiple null values in MongoDB. Instead, we check for duplicates in the controller.
    },

    avatarUrl: {
      type: String,
      default: null,
    },

    // Rewards / points earned by registering for events
    points: {
      type: Number,
      default: 0,
    },
  },
  {
    // Automatically adds createdAt and updatedAt fields
    timestamps: true,
  }
);

module.exports = mongoose.model("User", UserSchema);
