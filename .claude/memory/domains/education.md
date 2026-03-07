# Domain Knowledge — Education (EdTech)

> **Domain**: Education Technology (EdTech)
> Auto-loaded via `domain.lock` or `/set-domain education`

## Core Business Concepts

### Learning Management
- Courses with modules, lessons, and assessments
- Instructor-led vs self-paced learning
- Progress tracking and completion certificates
- Learning paths (ordered sequences of courses)
- Prerequisites and enrollment rules

### User Roles
- **Student**: Enrolls in courses, submits assignments, takes assessments
- **Instructor**: Creates content, grades work, manages courses
- **Admin**: Manages users, institutions, system settings
- **Parent/Guardian**: Views student progress (K-12)

### Academic Structure
- Institutions -> Departments -> Programs -> Courses -> Sections
- Academic terms (semesters, quarters, trimesters)
- Grading scales (letter, percentage, pass/fail)
- GPA calculation and transcript generation
- Credit hour tracking

---

## Modules

### 1. Course Management
**Entities**: Course, Module, Lesson, Content, Enrollment
**Key Rules**:
- Course versioning (update without affecting active enrollments)
- Content types: video, text, PDF, interactive, SCORM packages
- Drip content (release on schedule or based on progress)
- Enrollment limits and waitlists
- Course cloning for new terms

### 2. Assessments & Grading
**Entities**: Assessment, Question, Submission, Grade, Rubric
**Key Rules**:
- Question types: multiple choice, short answer, essay, coding, file upload
- Question banks with randomization
- Timed assessments with auto-submit
- Plagiarism detection integration (Turnitin)
- Rubric-based grading with criteria and levels
- Grade book with weighted categories
- Late submission policies (penalty percentage per day)

### 3. Live Learning
**Entities**: Session, Recording, Attendance, Whiteboard
**Key Rules**:
- Video conferencing integration (Zoom, Meet, custom)
- Screen sharing and collaborative whiteboard
- Breakout rooms for group activities
- Session recording with auto-captioning
- Attendance tracking (join time, duration)

### 4. Communication
**Entities**: Discussion, Announcement, Message, Notification
**Key Rules**:
- Course discussion forums (threaded)
- Direct messaging between students and instructors
- Announcements (course-wide, institution-wide)
- Email and push notification preferences
- Moderation tools for discussions

---

## Cross-Cutting Concerns

### Accessibility (MANDATORY)
- WCAG 2.1 AA compliance for all content
- Screen reader compatibility
- Closed captions for all video content
- Keyboard navigation support
- Alternative text for images
- Accessible document formats (tagged PDFs)

### Analytics & Reporting
- Student engagement metrics (time on content, login frequency)
- Assessment analytics (difficulty index, discrimination index)
- At-risk student identification (early warning system)
- Course completion rates and satisfaction scores
- Instructor dashboards with real-time class overview

### Privacy & Compliance
- **FERPA** (US): Student education records protection
- **COPPA** (US): Children under 13 data protection
- **GDPR** (EU): Data processing and consent
- Parental consent for minor students
- Data retention and purging policies per regulation

### Content Standards
- **SCORM 1.2 / 2004**: E-learning content packaging
- **xAPI (Tin Can)**: Learning experience tracking
- **LTI 1.3**: Tool interoperability (embed external tools)
- **QTI**: Question and test interchange format
