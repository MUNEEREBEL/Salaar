# 🦁 SALAAR - Civic Reporting App

**Enterprise-grade civic reporting application with Prabhas-style Telugu notifications, real-time tracking, and comprehensive role-based access control.**

![Salaar App](https://img.shields.io/badge/Flutter-3.x-blue) ![Supabase](https://img.shields.io/badge/Supabase-Database-green) ![Android](https://img.shields.io/badge/Android-5.0+-brightgreen) ![iOS](https://img.shields.io/badge/iOS-12.0+-lightgrey)

## 📱 Overview

Salaar is a comprehensive civic reporting application that enables citizens to report local issues, allows workers to manage and resolve these issues, and provides administrators with powerful management tools. The app features Prabhas-style Telugu notifications, real-time location tracking, and a modern dark theme inspired by the Salaar movie aesthetic.

## 🎯 Key Features

### 👥 Multi-Role System
- **Citizens**: Report issues, track progress, earn XP, participate in community
- **Workers**: Manage assigned tasks, real-time GPS tracking, photo documentation
- **Administrators**: Oversee all operations, assign workers, send notifications
- **Developers**: Access debugging tools and system analytics

### 🔔 Prabhas-Style Notifications
- **Telugu Language Support** with authentic Prabhas movie references
- **Random Message Selection** from 60+ unique notification templates
- **Custom Sound Effects** for different notification types
- **Cultural Relevance** with Baahubali, Salaar, Rebel, and other movie themes

### 📍 Real-Time Features
- **GPS Location Tracking** with background services
- **Live Issue Mapping** with clustering for multiple reports
- **Real-Time Status Updates** across all user roles
- **Background Location Sync** every 15 minutes for workers

### 🎨 Modern UI/UX
- **Salaar Dark Theme** with gold accents (#D4AF37)
- **Responsive Design** that works on all screen sizes
- **Smooth Animations** and transitions
- **Dinosaur Loading Screen** with emoji animations

## 🛠️ Technology Stack

### Frontend
- **Flutter 3.x** - Cross-platform mobile development
- **Dart** - Programming language
- **Provider** - State management
- **Material Design 3** - UI components

### Backend & Database
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database
  - Real-time subscriptions
  - Row Level Security (RLS)
  - Storage buckets for images
- **PostgreSQL** - Primary database with custom functions

### APIs & Services
- **Geoapify** - Geocoding, reverse geocoding, and routing
- **OpenStreetMap** - Map tiles and geographic data
- **Flutter Local Notifications** - Push notifications
- **Image Picker** - Camera and gallery integration

### Key Packages
```yaml
dependencies:
  flutter: ^3.0.0
  supabase_flutter: ^2.0.0
  provider: ^6.0.0
  geolocator: ^10.0.0
  image_picker: ^1.0.0
  flutter_local_notifications: ^16.0.0
  url_launcher: ^6.0.0
  shared_preferences: ^2.0.0
```

## 🗄️ Database Schema

### Core Tables

#### `profiles` Table
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT,
  username TEXT UNIQUE,
  email TEXT,
  phone TEXT,
  role TEXT CHECK (role IN ('citizen', 'worker', 'admin', 'developer')),
  department_id UUID REFERENCES departments(id),
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### `issues` Table
```sql
CREATE TABLE issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  issue_type TEXT NOT NULL,
  description TEXT NOT NULL,
  location_lat DECIMAL(10,8) NOT NULL,
  location_lng DECIMAL(11,8) NOT NULL,
  address TEXT,
  priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status TEXT CHECK (status IN ('pending', 'verified', 'in_progress', 'completed')) DEFAULT 'pending',
  assigned_worker_id UUID REFERENCES profiles(id),
  completion_image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### `departments` Table
```sql
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### `discussions` Table
```sql
CREATE TABLE discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id UUID REFERENCES profiles(id),
  comment_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Database Functions

#### XP Calculation Function
```sql
CREATE OR REPLACE FUNCTION calculate_user_xp(user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  total_reports INTEGER;
  completed_reports INTEGER;
  verified_reports INTEGER;
  xp_points INTEGER;
BEGIN
  -- Count reports by status
  SELECT COUNT(*) INTO total_reports FROM issues WHERE issues.user_id = user_id;
  SELECT COUNT(*) INTO completed_reports FROM issues WHERE issues.user_id = user_id AND status = 'completed';
  SELECT COUNT(*) INTO verified_reports FROM issues WHERE issues.user_id = user_id AND status = 'verified';
  
  -- Calculate XP: 10 per report + 10 per verified + 20 per completed
  xp_points := (total_reports * 10) + (verified_reports * 10) + (completed_reports * 20);
  
  RETURN xp_points;
END;
$$ LANGUAGE plpgsql;
```

#### Nearby Issues Function
```sql
CREATE OR REPLACE FUNCTION get_nearby_issues(
  user_lat DECIMAL(10,8),
  user_lng DECIMAL(11,8),
  radius_km DECIMAL
)
RETURNS TABLE (
  id UUID,
  issue_type TEXT,
  description TEXT,
  location_lat DECIMAL(10,8),
  location_lng DECIMAL(11,8),
  address TEXT,
  priority TEXT,
  status TEXT,
  distance_km DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.issue_type,
    i.description,
    i.location_lat,
    i.location_lng,
    i.address,
    i.priority,
    i.status,
    (6371 * acos(
      cos(radians(user_lat)) * 
      cos(radians(i.location_lat)) * 
      cos(radians(i.location_lng) - radians(user_lng)) + 
      sin(radians(user_lat)) * 
      sin(radians(i.location_lat))
    )) AS distance_km
  FROM issues i
  WHERE (6371 * acos(
    cos(radians(user_lat)) * 
    cos(radians(i.location_lat)) * 
    cos(radians(i.location_lng) - radians(user_lng)) + 
    sin(radians(user_lat)) * 
    sin(radians(i.location_lat))
  )) <= radius_km
  ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;
```

## 🔧 How It Works

### 1. User Authentication & Roles
```
User Registration → Email Verification → Role Assignment → Profile Creation
```

- **Citizens**: Can report issues, view community, track their reports
- **Workers**: Can view assigned tasks, update status, upload completion photos
- **Administrators**: Can manage all users, assign workers, send notifications
- **Developers**: Can access debugging tools and system analytics

### 2. Issue Reporting Flow
```
1. Citizen opens app → 2. Clicks "Report Issue" → 3. Fills form with location → 4. Takes photos → 5. Submits report → 6. Gets XP and notification
```

### 3. Worker Task Management
```
1. Admin assigns worker → 2. Worker gets notification → 3. Worker views task → 4. Worker updates status → 5. Worker uploads completion photo → 6. User gets completion notification
```

### 4. Real-Time Updates
- **Database Triggers** update issue status in real-time
- **Supabase Realtime** syncs changes across all connected clients
- **Background Services** track worker locations every 15 minutes
- **Push Notifications** inform users of status changes

### 5. XP & Leveling System
```
Report Submitted: +10 XP
Report Verified: +10 XP  
Report Completed: +20 XP
Level Calculation: Based on total XP with 5 levels
```

**Level Names:**
1. The Beginning
2. Ghaniyaar
3. Mannarasi
4. Shouryaanga
5. SALAAR

## 🔔 Notification System

### Prabhas-Style Telugu Notifications

The app features a unique notification system with Prabhas movie references:

#### Worker Assignment Messages (20+ variants)
```dart
"**{worker_name}** ni assign chesaam... *Darling* laga fix chestaadu! 🚀"
"**{worker_name}** ready ga unnaadu... *Baahubali* laga problem ni destroy chestaadu! 💪"
```

#### Task Completion Messages (20+ variants)
```dart
"*Baahubali laga fix chesaamu! +20XP meeke!* 🏆 **{worker_name}**"
"*Rebel style lo solve chesaam! +20XP meku gift!* 💝 **{worker_name}**"
```

#### Admin Notifications (24+ variants)
```dart
"*Baahubali dialogue: 'Nenu osthunna...' {message}* 📢"
"*Salaar update: 'Discipline maintain cheyali...' {message}* ⚡"
```

### Custom Sound System
- `xp_sound.mp3` - XP rewards and general notifications
- `task_sound.mp3` - Task assignments and alerts
- `worker_assignment.mp3` - Worker assignment notifications
- `reminder_sound.mp3` - Reminders and updates

## 📱 App Architecture

### State Management
- **Provider Pattern** for state management
- **AuthProviderComplete** - User authentication and profile
- **IssuesProvider** - Issue management and CRUD operations
- **CommunityProvider** - Community features and discussions
- **NavigationProvider** - Bottom navigation state

### Service Layer
- **PrabhasNotificationService** - Telugu notifications with movie references
- **WorkStatisticsService** - Real-time XP and level calculations
- **ImageUploadService** - Photo upload to Supabase storage
- **LocationService** - GPS tracking and geocoding
- **AppInitializationService** - App startup and service initialization

### Screen Structure
```
lib/screens/
├── auth/           # Authentication screens
├── citizen/        # Citizen role screens
├── worker/         # Worker role screens
├── admin/          # Admin role screens
├── developer/      # Developer role screens
└── shared/         # Shared components
```

## 🚀 Setup & Installation

### Prerequisites
- Flutter 3.x or higher
- Android Studio / Xcode
- Supabase account
- Geoapify API key

### 1. Clone Repository
```bash
git clone <repository-url>
cd salaar
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Environment Variables
Create `lib/config/app_config.dart`:
```dart
class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String geoapifyApiKey = 'YOUR_GEOAPIFY_API_KEY';
}
```

### 4. Setup Supabase
1. Create a new Supabase project
2. Run the database schema SQL scripts
3. Create storage bucket named `issue-images`
4. Configure Row Level Security policies
5. Add custom sound files to `assets/sounds/`

### 5. Run the App
```bash
flutter run
```

## 📊 Features by Role

### 👤 Citizen Features
- **Home Dashboard**: Weather, XP display, quick actions
- **Report Issues**: Drag-to-locate, photo upload, priority selection
- **My Reports**: Track submitted issues and their status
- **Community**: Leaderboard, discussions, community insights
- **Profile**: Statistics, level progression, settings
- **Map View**: See all issues in the area

### 👷 Worker Features
- **Task Dashboard**: Assigned tasks with priority indicators
- **Task Management**: Update status, upload completion photos
- **Location Tracking**: Background GPS updates every 15 minutes
- **Navigation**: Route planning to issue locations
- **Profile**: Work statistics, department info, settings
- **Map View**: See assigned tasks on map

### 👨‍💼 Admin Features
- **Dashboard**: System overview, statistics, quick actions
- **Reports Management**: View all reports, assign workers, update status
- **Worker Management**: Create worker accounts, assign departments
- **User Management**: View all users, manage permissions
- **Notifications**: Send custom notifications to all users
- **Analytics**: System performance, user activity, issue trends

### 👨‍💻 Developer Features
- **Debug Dashboard**: System logs, error tracking, performance metrics
- **API Testing**: Test database functions and API endpoints
- **Mock Data**: Generate sample data for testing
- **Environment Switching**: Toggle between dev/staging/prod
- **System Monitoring**: Real-time system health and performance

## 🔒 Security Features

### Row Level Security (RLS)
- **User Isolation**: Users can only see their own data
- **Role-Based Access**: Different permissions for each role
- **Data Protection**: Sensitive data is protected at database level

### Authentication
- **Email/Password**: Secure authentication with Supabase Auth
- **Session Management**: Automatic token refresh
- **Role Verification**: Server-side role validation

### Data Validation
- **Input Sanitization**: All user inputs are validated
- **File Upload Security**: Image uploads are validated and secured
- **Location Privacy**: Location data is encrypted and protected

## 📈 Performance Optimizations

### Database
- **Indexed Queries**: Optimized database queries with proper indexing
- **Connection Pooling**: Efficient database connection management
- **Query Optimization**: Minimized database calls and optimized queries

### Mobile App
- **Lazy Loading**: Images and data are loaded on demand
- **Caching**: Local caching for frequently accessed data
- **Background Services**: Efficient background location tracking
- **Memory Management**: Optimized memory usage and garbage collection

### Real-Time Updates
- **Selective Subscriptions**: Only subscribe to relevant data changes
- **Debounced Updates**: Prevent excessive API calls
- **Offline Support**: Basic offline functionality with sync on reconnect

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] User registration and login
- [ ] Issue reporting with photos
- [ ] Worker task assignment and completion
- [ ] Admin notification sending
- [ ] Real-time updates across devices
- [ ] Location tracking and mapping
- [ ] XP calculation and level progression
- [ ] Prabhas-style notifications

## 🚀 Deployment

### Android APK
```bash
flutter build apk --release
```

### iOS App Store
```bash
flutter build ios --release
```

### Web Deployment
```bash
flutter build web --release
```

## 📝 API Documentation

### Supabase Endpoints
- **Authentication**: `/auth/v1/`
- **Database**: `/rest/v1/`
- **Storage**: `/storage/v1/`
- **Realtime**: `/realtime/v1/`

### Custom Functions
- `calculate_user_xp(user_id)` - Calculate user XP points
- `get_nearby_issues(lat, lng, radius)` - Get issues within radius
- `increment_profile_counters(user_id, type)` - Update user statistics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Prabhas** - Inspiration for the notification system and app theme
- **Supabase** - Backend infrastructure and real-time capabilities
- **Flutter Team** - Cross-platform development framework
- **OpenStreetMap** - Geographic data and mapping services

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation wiki

---

**Made with ❤️ for the community by the Salaar Development Team**

*"Nenu osthunna... Salaar laga discipline maintain cheyali!"* 🦁⚡