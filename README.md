# Learning App Project

## Overview

This project is a comprehensive learning application built with Flutter for the frontend and Python FastAPI with Neo4j for the backend. The app features multiple modules focused on personal productivity, learning management, and self-regulation.

## Key Modules

### 1. Task Management
- Task creation, editing and tracking
- Energy-based task categorization
- Task completion metrics and analytics
- Time blocking integration with calendar

### 2. Learning Module
- Topic management with spaced repetition system
- Learning stages tracking (first_time, early_stage, mid_stage, late_stage, mastered)
- Knowledge graph visualization
- Session planner for optimized study sessions
- Educational content system

### 3. Self-Regulation Module
- Energy level tracking
- Focus sessions
- Habit building
- Reflection journal
- Mood and motivation tracking

## Technical Architecture

### Frontend (Flutter)
- Uses Provider pattern for state management
- SQFLite for local storage and offline functionality
- Design follows a dark theme with purple accent colors
- Custom UI components for specialized views (dashboards, charts, etc.)

### Backend (Python)
- FastAPI for RESTful API endpoints
- Neo4j graph database for storing topics, relationships, and content
- Day spacing algorithm for spaced repetition learning
- Analytics processing for user progress metrics

### Content System
- Supports multiple content types:
  - Articles (markdown formatted)
  - Interactive guides (step-by-step)
  - Self-assessment quizzes
- Content is linked to topics for contextual learning
- Custom viewers for each content type

## Key Features

- **Knowledge Graph**: Visual representation of learning topics and their relationships
- **Spaced Repetition**: Intelligent scheduling of topic reviews based on difficulty feedback
- **Session Planning**: Creates optimized study sessions based on energy levels and topic relationships
- **Progress Visualization**: Comprehensive charts and metrics for tracking learning progress
- **Sync System**: Offline-first architecture with background synchronization
- **Calendar Integration**: Supports both ICS and Google Calendar integration

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Python 3.13+
- Neo4j database

### Installation

1. Clone the repository:
```
git clone https://github.com/DigitalDemi/Project-X.git
```

2. Install frontend dependencies:
```
cd frontend
flutter pub get
```

3. Install backend dependencies:
```
cd backend
pip install -e .
```

4. Configure database connection:
Edit the Neo4j connection details in `backend/database.py`

5. Start the backend server:
```
uvicorn backend.backend:app --reload
```

6. Run the Flutter app:
```
cd frontend
flutter run
```

## Project Structure

- `/frontend`: Flutter application
  - `/lib/models`: Data models
  - `/lib/services`: Service classes for API and local storage
  - `/lib/ui`: UI components and screens
- `/backend`: Python API server
  - `backend.py`: Main API endpoints
  - `database.py`: Neo4j connection and queries
  - `day_spacing_algorithm.py`: Spaced repetition algorithm

## Future Development

- Enhanced analytics and recommendations
- More content types (video, audio, interactive exercises)
- Machine learning integration for personalized learning paths
- Community features and content sharing
- Extended mobile platform support

## Contributors

- Digital Demi (Project Lead)
