# AMIA FEST (Askesis)

> A modern digital platform for managing and participating in an Arts & Fest event.

**Amia Fest** is a digital fest management platform designed to simplify the organization, registration, participation, judging, and result management of arts and cultural competitions.

The platform provides a centralized system for participants, fest leaders, judges, and administrators, reducing manual work and making the overall fest management process faster and more organized.

---

## ✨ Features

### 👨‍🎓 Participant Management

* Student registration and management
* Participant information management
* Program participation
* Category and group-based participation
* Registration validation

### 🏆 Program & Competition Management

* Manage fest programs
* Assign participants to programs
* Support different competition categories
* Track participant registrations
* Manage competition information

### 👨‍⚖️ Judging System

* Dedicated judging workflow
* Enter marks for participants
* Calculate scores
* Manage competition results
* Reduce manual calculation errors

### 🏠 House / Team Management

* Organize participants into houses or teams
* Track house participation
* Maintain house-wise performance
* Support overall fest scoring

### 📊 Results & Scoring

* Automatic score calculation
* Participant rankings
* Program-wise results
* House-wise performance
* Overall fest results

### 🔐 Role-Based Access

The platform is designed around different user roles, allowing each type of user to access the features relevant to their responsibility.

Typical roles include:

* **Admin**
* **Fest Leader**
* **Judge**

---

## 🖥️ Public Fest Portal

The public-facing Amia Fest portal allows users to access fest-related information and public features.

🌐 **Live Website:**
[Amia Fest — Public Portal](https://amiafestapp.vercel.app/#/public)

---

## 🏗️ Project Architecture

The project follows a modern application architecture with a Flutter-based user interface and backend services for handling application data and business logic.

```text
Amia Fest
│
├── Flutter Application
│   ├── Authentication
│   ├── Student Management
│   ├── Program Management
│   ├── Leader Portal
│   ├── Judge Portal
│   ├── Admin Portal
│   └── Results
│
├── Backend / API
│   ├── Authentication
│   ├── Student APIs
│   ├── Program APIs
│   ├── Registration APIs
│   ├── Judging APIs
│   └── Result APIs
│
└── Database
    ├── Students
    ├── Programs
    ├── Registrations
    ├── Marks
    ├── Houses
    └── Results
```

---

## 🛠️ Technology Stack

### Frontend

* **Flutter**
* **Dart**
* Flutter Web
* Responsive UI
* Material Design

### Backend

* REST API
* Server-side application
* Authentication & authorization
* API-based data communication

### Database

The application uses a structured database system for storing:

* Student information
* Program information
* Registrations
* Marks
* House information
* Results

### Development Tools

* Git
* GitHub
* Visual Studio Code
* Android Studio
* Flutter SDK

---

## 🔄 Application Workflow

```text
                    ┌──────────────┐
                    │    Admin     │
                    └──────┬───────┘
                           │
                    Manage Fest Data
                           │
                           ▼
                  ┌─────────────────┐
                  │  Fest Platform  │
                  └────────┬────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
     Fest Leader        Judge           Participant
          │                │                │
          ▼                ▼                ▼
    Registration        Marks          Programs
          │                │                │
          └────────────────┼────────────────┘
                           ▼
                    ┌──────────────┐
                    │   Results    │
                    └──────────────┘
```

---

## 📱 Main Modules

| Module              | Purpose                               |
| ------------------- | ------------------------------------- |
| 🔐 Authentication   | Secure user access                    |
| 👨‍🎓 Students      | Manage student information            |
| 🎭 Programs         | Manage competition programs           |
| 🧑‍💼 Leader Portal | Manage registrations and participants |
| ⚖️ Judge Portal     | Enter and manage competition marks    |
| 🏠 Houses           | Manage team/house participation       |
| 🏆 Results          | Calculate and display results         |
| 🌐 Public Portal    | Provide public fest information       |
| 👨‍💻 Admin Portal  | Manage the complete fest system       |

---

## 🎯 Project Goals

The main goals of Amia Fest are:

* Digitize traditional fest management
* Reduce paperwork
* Reduce manual data-entry errors
* Simplify participant registration
* Make judging faster
* Automate result calculations
* Provide centralized fest data
* Improve communication between organizers and participants
* Provide a better digital experience for the entire fest

---

## 🔒 Security

The application should follow secure development practices including:

* Role-based access control
* Protected API endpoints
* Secure authentication
* Input validation
* Server-side validation
* Environment variables for secrets
* HTTPS communication

---

## 📈 Future Improvements

Possible future improvements include:

* 📱 Dedicated Android/iOS applications
* 📺 Live result display
* 📊 Advanced analytics dashboard
* 🏆 Live house ranking
* 📥 Excel/CSV import and export
* 🔔 Notifications
* 📷 QR-based participant verification
---


## 👨‍💻 Developer

**Muhsin Ahamed**

Flutter & Software Developer

* GitHub: [muhsin-ahamed](https://github.com/muhsin-ahamed)
* LinkedIn: [Muhsin Ahamed on LinkedIn](https://www.linkedin.com/in/muhsin-ahamed-t/)

---

## ⭐ Support

If you find this project useful, consider giving the repository a ⭐ on GitHub.
**Built with Flutter & ❤️ for a better digital fest experience.**

