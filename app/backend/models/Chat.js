// models/Chat.js
// ─────────────────────────────────────────────────────────────────────────────
// Chat schema — a thread between a user (attendee) and an event organizer.
// One chat thread can optionally be linked to a specific event.
// ─────────────────────────────────────────────────────────────────────────────

const mongoose = require("mongoose");

const ChatSchema = new mongoose.Schema(
  {
    // The attendee side of the conversation
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // The organizer side of the conversation
    organizer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // Optional: which event this chat is about
    event: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Event",
      default: null,
    },

    // Cache the last message for quick display in the chat list
    lastMessage: {
      type: String,
      default: null,
    },

    lastMessageAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// Message schema — individual messages inside a Chat thread.
// Stored in a separate collection for scalability.
// ─────────────────────────────────────────────────────────────────────────────

const MessageSchema = new mongoose.Schema(
  {
    // Which chat thread this message belongs to
    chat: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Chat",
      required: true,
    },

    // The user who sent this message
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    content: {
      type: String,
      required: [true, "Message content cannot be empty"],
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

const Chat    = mongoose.model("Chat", ChatSchema);
const Message = mongoose.model("Message", MessageSchema);

module.exports = { Chat, Message };
