// Portfolio content shared by the retro OS pages and the 3D room panels.

const contactEmail = 'Saksham200111@gmail.com';
const contactPhone = '+91 88104 35497';
const contactPhoneUri = 'tel:+918810435497';
const contactLinkedIn = 'https://www.linkedin.com/in/saksham-bir-singh';
const contactGithub = 'https://github.com/Saksham-07';
const contactLocation = 'Faridabad, Haryana, India';

const aboutName = 'SAKSHAM BIR SINGH';
const aboutTitle = 'APPLICATION DEVELOPER';

const aboutProfile =
    'Application Developer with 2.5+ years of experience engineering high-performance cross-platform mobile and web applications. Proven ability to translate complex UI/UX designs into responsive, intuitive user experiences using Dart, Flutter, and Python. Specialized in building secure, data-driven enterprise tools and dashboards, with a strict focus on writing clean, maintainable code.';

const aboutSkills = <(String, List<String>)>[
  ('LANGUAGES', ['Dart', 'Python', 'Java', 'JavaScript', 'HTML5', 'CSS3', 'XML']),
  ('FRAMEWORKS & LIBRARIES', ['Flutter', 'Django', 'Android', 'Material UI']),
  ('STATE MANAGEMENT & NETWORKING', ['BLOC', 'Provider', 'REST API', 'Dio']),
  ('TOOLS & COMPETENCIES', ['GitHub', 'RFID Integration', 'API Integration', 'SQL Server', 'Flask']),
];

class Job {
  const Job(this.role, this.company, this.date, this.bullets);
  final String role, company, date;
  final List<String> bullets;
}

const aboutJobs = <Job>[
  Job('Flutter Application Developer', 'Paramount Product Private Limited', 'Jan 2024 - Present', [
    'Led full-lifecycle development of PPMS, a cross-platform solution engineered to digitize and automate complex garment manufacturing and export operations.',
    'Architected a real-time Garment Audit module, implementing rigorous Quality Assurance workflows to ensure export-grade standards and minimize production defects.',
    'Integrated a hardware-level RFID scanning system to provide granular, end-to-end visibility across the supply chain, from raw material intake to final shipment.',
    'Developed a Machine Maintenance & Repair ecosystem, featuring an automated request-and-approval pipeline to minimize factory downtime and optimize asset lifecycle management.',
    'Built a smooth API-driven flow that pulls updated records from the database and presents them directly in the app for users.',
  ]),
  Job('Web Developer', 'Paramount Product Private Limited', 'Jan 2024 - April 2024', [
    'Architected scalable web applications using Django and RESTful APIs.',
    'Crafted responsive interfaces using HTML5, CSS3, and JavaScript.',
    'Managed server environments ensuring 99.9% system uptime.',
  ]),
  Job('Android Developer Trainee', 'SignCatch', 'Jan 2023 - July 2023', [
    'Engineered high-fidelity Native UI/UX interfaces using Java and Kotlin.',
    'Managed end-to-end RESTful API integration and data synchronization.',
  ]),
];

class KeyProject {
  const KeyProject(this.title, this.tech, this.desc);
  final String title, tech, desc;
}

const aboutKeyProjects = <KeyProject>[
  KeyProject(
      'Enterprise RFID Supply Chain Tracker',
      'Flutter, Dart, Hardware APIs, SQL Server',
      'Engineered a secure mobile RFID scanning architecture. The application instantly captures, decodes, and authenticates hardware tags on the factory floor, validating data against strict protocols before saving it to the database for real-time supply chain transparency with international buyers.'),
  KeyProject(
      'Real-Time Garment Audit Suite',
      'Flutter, Dart, BLoC, REST API',
      'Architected a comprehensive multi-stage Quality Assurance module spanning Sampling, Sewing, Finishing, and End-Line. Empowered floor employees to log real-time defect data at any stage, driving immediate corrective actions that significantly reduced material wastage and maintained uninterrupted production flow.'),
  KeyProject(
      'Financial & Sales Dashboard',
      'Flutter, Provider, BLOC',
      'Engineered modern UI/UX with skeleton loading animations and fluid backgrounds for complex monthly summary tables without relying on clunky mobile charts.'),
  KeyProject(
      'Food Delivery Application',
      'Flutter, Dart, Provider',
      'Developed a high-performance food delivery application focusing on daily user engagement, responsive UI, and robust state management.'),
];

class Education {
  const Education(this.title, this.place, this.score);
  final String title, place, score;
}

const aboutEducation = <Education>[
  Education("Bachelor's of Technology", 'J.C Bose University • 2019-2023', 'CGPA - 8.1'),
  Education('Senior Secondary', 'Aggarwal Public School • 2017-2019', 'Percentile - 67%'),
];
