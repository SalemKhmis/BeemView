import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application Localizations supporting English (`en`) and Arabic (`ar`).
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Auth & Login
      'app_title': 'BeemView',
      'welcome_back': 'Welcome back',
      'sign_in_subtitle': 'Sign in to access your workspace',
      'username': 'Username',
      'username_hint': 'Enter your username',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'sign_in': 'Sign In',
      'signing_in': 'Signing in...',
      'tenant_subdomain': 'Tenant',
      'login_failed': 'Login failed. Please check credentials.',

      // Home & Dashboard
      'dashboard': 'Dashboard',
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon',
      'good_evening': 'Good evening',
      'real_time_analytics': 'Real-time Analytics',
      'overview_360': '360° OVERVIEW',
      'live': 'LIVE',
      'health_score': 'HEALTH',
      'optimal': 'Optimal',
      'on_track': 'On Track',
      'needs_focus': 'Needs Focus',
      'projects': 'Projects',
      'tasks': 'Tasks',
      'velocity': 'Velocity',
      'active': 'active',
      'done': 'done',
      'new_project': 'New Project',
      'new_task': 'New Task',
      'task_distribution': 'Task Distribution',
      'total': 'Total',
      'high_priority_work': 'High Priority Work:',
      'urgent': 'Urgent',
      'high': 'High',
      'medium': 'Medium',
      'low': 'Low',
      'requires_attention': 'Requires Attention',
      'pending': 'pending',
      'workspace_healthy': 'Workspace is completely healthy! No urgent bottlenecks.',
      'active_initiatives': 'Active Initiatives',
      'view_all': 'View All',
      'no_initiatives': 'No active initiatives found. Create one with "+ New Project".',
      'aggregating_analytics': 'Aggregating real-time analytics...',
      'try_again': 'Try Again',

      // Projects List
      'search_projects': 'Search projects...',
      'no_projects_found': 'No projects found',
      'create_first_project': 'Create your first project to get started',
      'load_more': 'Load More',
      'all_projects_loaded': 'All projects loaded',

      // Task Statuses
      'to_do': 'To Do',
      'in_progress': 'In Progress',
      'review': 'Review',
      'on_hold': 'On Hold',
      'status_done': 'Done',
      'canceled': 'Canceled',
      'changes_requested': 'Changes Requested',
      'blocked': 'Blocked',

      // Task Details & Project Tasks
      'project_tasks': 'Project Tasks',
      'search_tasks': 'Search tasks...',
      'filter_tasks': 'Filter tasks by status',
      'all': 'All',
      'no_tasks_found': 'No tasks found',
      'task_details': 'Task Details',
      'due_date': 'Due Date',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'assignees': 'Assignees',
      'no_assignees': 'No assignees',
      'comments': 'Comments',
      'no_comments': 'No comments yet',
      'add_comment': 'Add a comment...',
      'send_comment': 'Send',
      'update_status': 'Update Status',
      'optional_note': 'Optional status note...',
      'save_status': 'Save Status',
      'updating': 'Updating...',
      'status_updated': 'Status updated successfully',
      'is_private': 'Private Task',
      'private_task_hint': 'Visible only to assigned members',

      // Forms (Add Project & Add Task)
      'create_project_title': 'New Project',
      'create_task_title': 'New Task',
      'project_name': 'Project Name',
      'project_name_hint': 'e.g. Mobile Application V2',
      'task_name': 'Task Name',
      'task_name_hint': 'e.g. Implement user authentication',
      'description': 'Description',
      'description_hint': 'Provide additional context...',
      'status': 'Status',
      'priority_label': 'Priority',
      'select_start_date': 'Select start date',
      'select_end_date': 'Select end date',
      'select_due_date': 'Select due date',
      'dates_required': 'Please select dates',
      'create_project_btn': 'Create Project',
      'create_task_btn': 'Create Task',
      'creating': 'Creating...',
      'project_created': 'Project created successfully',
      'task_created': 'Task created successfully',
      'field_required': 'This field is required',

      // Common & Settings
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'theme': 'Theme',
      'english': 'English',
      'arabic': 'العربية',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'save': 'Save',
      'session_expired': 'Session expired. Please log in again.',
      'error': 'Error',
      'success': 'Success',

      // Profile & Account
      'profile': 'Profile',
      'account_information': 'Account Information',
      'user_profile': 'User Profile',
      'personal_info': 'Personal Info',
      'workspace_info': 'Workspace Info',
      'user_id': 'User ID',
      'full_name': 'Full Name',
      'email_address': 'Email Address',
      'phone_number': 'Phone Number',
      'role': 'Role',
      'job_title': 'Job Title',
      'department': 'Department',
      'account_status': 'Account Status',
      'active_status': 'Active',
      'member_since': 'Member Since',
      'tenant': 'Tenant Workspace',
      'preferences_settings': 'Preferences & Settings',
      'session_security': 'Session & Security',
      'authenticated_session': 'Authenticated Session',
      'secure_storage_active': 'Token securely stored',
      'copied_to_clipboard': 'Copied to clipboard',
      'refresh_profile': 'Refresh Profile',
      'profile_load_failed': 'Failed to load profile',
    },
    'ar': {
      // Auth & Login
      'app_title': 'بيم فيو',
      'welcome_back': 'مرحبًا بعودتك',
      'sign_in_subtitle': 'تسجيل الدخول للوصول إلى مساحة عملك',
      'username': 'اسم المستخدم',
      'username_hint': 'أدخل اسم المستخدم',
      'password': 'كلمة المرور',
      'password_hint': 'أدخل كلمة المرور',
      'sign_in': 'تسجيل الدخول',
      'signing_in': 'جاري تسجيل الدخول...',
      'tenant_subdomain': 'جهة العمل',
      'login_failed': 'فشل تسجيل الدخول. يرجى التحقق من البيانات.',

      // Home & Dashboard
      'dashboard': 'لوحة التحكم',
      'good_morning': 'صباح الخير',
      'good_afternoon': 'مساء الخير',
      'good_evening': 'مساء الخير',
      'real_time_analytics': 'التحليلات المباشرة',
      'overview_360': 'نظرة شاملة 360°',
      'live': 'مباشر',
      'health_score': 'مؤشر الصحة',
      'optimal': 'ممتاز',
      'on_track': 'على المسار',
      'needs_focus': 'يحتاج تركيز',
      'projects': 'المشاريع',
      'tasks': 'المهام',
      'velocity': 'معدل الإنجاز',
      'active': 'نشط',
      'done': 'مكتمل',
      'new_project': 'مشروع جديد',
      'new_task': 'مهمة جديدة',
      'task_distribution': 'توزيع المهام',
      'total': 'الإجمالي',
      'high_priority_work': 'مهام عالية الأولوية:',
      'urgent': 'عاجل',
      'high': 'مرتفع',
      'medium': 'متوسط',
      'low': 'منخفض',
      'requires_attention': 'تتطلب اهتماماً',
      'pending': 'معلقة',
      'workspace_healthy': 'مساحة العمل في حالة ممتازة! لا توجد عقبات عاجلة.',
      'active_initiatives': 'المبادرات النشطة',
      'view_all': 'عرض الكل',
      'no_initiatives': 'لم يتم العثور على مبادرات نشطة. أنشئ مبادرة عبر "+ مشروع جديد".',
      'aggregating_analytics': 'جاري تجميع التحليلات المباشرة...',
      'try_again': 'إعادة المحاولة',

      // Projects List
      'search_projects': 'البحث في المشاريع...',
      'no_projects_found': 'لم يتم العثور على مشاريع',
      'create_first_project': 'أنشئ أول مشروع للبدء',
      'load_more': 'تحميل المزيد',
      'all_projects_loaded': 'تم تحميل جميع المشاريع',

      // Task Statuses
      'to_do': 'قيد الانتظار',
      'in_progress': 'قيد التنفيذ',
      'review': 'قيد المراجعة',
      'on_hold': 'معلق',
      'status_done': 'مكتمل',
      'canceled': 'ملغى',
      'changes_requested': 'تعديلات مطلوبة',
      'blocked': 'محظور',

      // Task Details & Project Tasks
      'project_tasks': 'مهام المشروع',
      'search_tasks': 'البحث في المهام...',
      'filter_tasks': 'تصفية المهام حسب الحالة',
      'all': 'الكل',
      'no_tasks_found': 'لم يتم العثور على مهام',
      'task_details': 'تفاصيل المهمة',
      'due_date': 'تاريخ الاستحقاق',
      'start_date': 'تاريخ البدء',
      'end_date': 'تاريخ الانتهاء',
      'assignees': 'المكلفون',
      'no_assignees': 'لا يوجد مكلفون',
      'comments': 'التعليقات',
      'no_comments': 'لا توجد تعليقات حتى الآن',
      'add_comment': 'إضافة تعليق...',
      'send_comment': 'إرسال',
      'update_status': 'تحديث الحالة',
      'optional_note': 'ملاحظة اختيارية حول الحالة...',
      'save_status': 'حفظ الحالة',
      'updating': 'جاري التحديث...',
      'status_updated': 'تم تحديث الحالة بنجاح',
      'is_private': 'مهمة خاصة',
      'private_task_hint': 'مرئية فقط للأعضاء المكلفين',

      // Forms (Add Project & Add Task)
      'create_project_title': 'مشروع جديد',
      'create_task_title': 'مهمة جديدة',
      'project_name': 'اسم المشروع',
      'project_name_hint': 'مثال: تطبيق الهاتف الذكي الإصدار 2',
      'task_name': 'اسم المهمة',
      'task_name_hint': 'مثال: تنفيذ تسجيل الدخول للمستخدمين',
      'description': 'الوصف',
      'description_hint': 'أدخل تفاصيل وسياق إضافي...',
      'status': 'الحالة',
      'priority_label': 'الأولوية',
      'select_start_date': 'اختر تاريخ البدء',
      'select_end_date': 'اختر تاريخ الانتهاء',
      'select_due_date': 'اختر تاريخ الاستحقاق',
      'dates_required': 'يرجى تحديد التواريخ',
      'create_project_btn': 'إنشاء المشروع',
      'create_task_btn': 'إنشاء المهمة',
      'creating': 'جاري الإنشاء...',
      'project_created': 'تم إنشاء المشروع بنجاح',
      'task_created': 'تم إنشاء المهمة بنجاح',
      'field_required': 'هذا الحقل مطلوب',

      // Common & Settings
      'language': 'اللغة',
      'dark_mode': 'الوضع الداكن',
      'light_mode': 'الوضع الفاتح',
      'theme': 'المظهر',
      'english': 'English',
      'arabic': 'العربية',
      'logout': 'تسجيل الخروج',
      'logout_confirm': 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'session_expired': 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
      'error': 'خطأ',
      'success': 'تم بنجاح',

      // Profile & Account
      'profile': 'الملف الشخصي',
      'account_information': 'معلومات الحساب',
      'user_profile': 'ملف المستخدم',
      'personal_info': 'المعلومات الشخصية',
      'workspace_info': 'معلومات مساحة العمل',
      'user_id': 'معرف المستخدم',
      'full_name': 'الاسم الكامل',
      'email_address': 'البريد الإلكتروني',
      'phone_number': 'رقم الهاتف',
      'role': 'الدور',
      'job_title': 'المسمى الوظيفي',
      'department': 'القسم',
      'account_status': 'حالة الحساب',
      'active_status': 'نشط',
      'member_since': 'عضو منذ',
      'tenant': 'مساحة عمل الجهة',
      'preferences_settings': 'التفضيلات والإعدادات',
      'session_security': 'الأمان والجلسة',
      'authenticated_session': 'جلسة مصادق عليها',
      'secure_storage_active': 'الرمز مخزن بأمان',
      'copied_to_clipboard': 'تم النسخ إلى الحافظة',
      'refresh_profile': 'تحديث الملف الشخصي',
      'profile_load_failed': 'فشل تحميل الملف الشخصي',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Getters for frequently accessed keys
  String get appTitle => translate('app_title');
  String get dashboard => translate('dashboard');
  String get projects => translate('projects');
  String get tasks => translate('tasks');
  String get logout => translate('logout');
  String get cancel => translate('cancel');
  String get logoutConfirm => translate('logout_confirm');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension on [BuildContext] for easy translation access: `context.tr('key')`
extension LocalizationExtension on BuildContext {
  String tr(String key) => AppLocalizations.of(this).translate(key);
  AppLocalizations get l10n => AppLocalizations.of(this);
}
