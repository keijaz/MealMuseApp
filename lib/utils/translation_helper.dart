import '../providers/locale_provider.dart';

/// Helper class to provide translated text based on current locale
class TranslationHelper {
  static String translate(String textEn, String textUr) {
    final locale = LocaleProvider().localeNotifier.value;
    final langCode = locale?.languageCode ?? 'en';
    return langCode == 'ur' ? textUr : textEn;
  }

  static String t(String textEn, String textUr) {
    return translate(textEn, textUr);
  }

  // Pre-defined translations
  static const Map<String, Map<String, String>> translations = {
    'language': {'en': 'Language', 'ur': 'زبان'},
    'english': {'en': 'English', 'ur': 'انگریزی'},
    'urdu': {'en': 'اردو', 'ur': 'اردو'},
    'darkMode': {'en': 'Dark Mode', 'ur': 'ڈارک موڈ'},
    'settings': {'en': 'Settings', 'ur': 'ترتیبات'},
    'account': {'en': 'Account', 'ur': 'اکاؤنٹ'},
    'home': {'en': 'Home', 'ur': 'ہوم'},
    'recipes': {'en': 'Recipes', 'ur': 'ریسیپیز'},
    'inventory': {'en': 'Inventory', 'ur': 'انوینٹری'},
    'addItem': {'en': 'Add Item', 'ur': 'آئٹم شامل کریں'},
    'searchAllItems': {'en': 'Search All Items', 'ur': 'تمام آئٹمز تلاش کریں'},
    'findRecipes': {'en': 'Find Recipes →', 'ur': 'ریسیپیز تلاش کریں →'},
    'searchInventoryItems': {'en': 'Search inventory items...', 'ur': 'انوینٹری کی آئٹمز تلاش کریں...'},
    'typeToSearch': {'en': 'Type to search your inventory items', 'ur': 'اپنی انوینٹری کی آئٹمز تلاش کرنے کے لیے ٹائپ کریں'},
    'noItemsFound': {'en': 'No items found', 'ur': 'کوئی آئٹمز نہیں ملے'},
    'noItemsFoundInCategory': {'en': 'No items found in this category', 'ur': 'اس کیٹیگری میں کوئی آئٹمز نہیں ملے'},
    'vegetables': {'en': 'Vegetables', 'ur': 'سبزی'},
    'fruits': {'en': 'Fruits', 'ur': 'پھل'},
    'protein': {'en': 'Protein', 'ur': 'پروٹین'},
    'dairy': {'en': 'Dairy', 'ur': 'ڈیری'},
    'grains': {'en': 'Grains', 'ur': 'اناج'},
    'beverages': {'en': 'Beverages', 'ur': 'مشروب'},
    'snacks': {'en': 'Snacks', 'ur': 'اسنیکس'},
    'spices': {'en': 'Spices', 'ur': 'مصالحے'},
    'other': {'en': 'Other', 'ur': 'دیگر'},
    'fruit': {'en': 'Fruit', 'ur': 'پھل'},
    'vegetable': {'en': 'Vegetable', 'ur': 'سبزی'},
    'grain': {'en': 'Grain', 'ur': 'اناج'},
    'beverage': {'en': 'Beverage', 'ur': 'مشروب'},
    'snack': {'en': 'Snack', 'ur': 'اسنیکس'},
    'deleteItem': {'en': 'Delete Item', 'ur': 'آئٹم حذف کریں'},
    'areYouSure': {'en': 'Are you sure you want to delete this item?', 'ur': 'کیا آپ یقینی ہیں کہ آپ اس آئٹم کو حذف کرنا چاہتے ہیں؟'},
    'cancel': {'en': 'Cancel', 'ur': 'منسوخ'},
    'delete': {'en': 'Delete', 'ur': 'حذف'},
    'edit': {'en': 'Edit', 'ur': 'ترمیم'},
    'quantity': {'en': 'Quantity', 'ur': 'مقدار'},
    'deletedSuccessfully': {'en': 'deleted successfully', 'ur': 'کامیابی سے حذف ہو گیا'},
    'errorDeleting': {'en': 'Error deleting', 'ur': 'حذف کرتے وقت خرابی'},
    'savedRecipes': {'en': 'Saved Recipes', 'ur': 'محفوظ ریسیپیز'},
    'searchRecipe': {'en': 'Search Recipe', 'ur': 'ریسیپی تلاش کریں'},
    'viewRecipe': {'en': 'View Recipe', 'ur': 'ریسیپی دیکھیں'},
    'remove': {'en': 'Remove', 'ur': 'ہٹائیں'},
    'loadingSavedRecipes': {'en': 'Loading your saved recipes...', 'ur': 'آپ کی محفوظ شدہ ریسیپیز لوڈ کی جا رہی ہیں...'},
    'noSavedRecipes': {'en': 'No Saved Recipes', 'ur': 'کوئی محفوظ ریسیپیز نہیں'},
    'saveRecipesToSee': {'en': 'Save recipes to see them here!', 'ur': 'ریسیپیز محفوظ کریں تاکہ وہ یہاں دکھیں!'},
    'retry': {'en': 'Retry', 'ur': 'دوبارہ کوشش کریں'},
    'recipeIdNotFound': {'en': 'Recipe ID not found', 'ur': 'ریسیپی آئی ڈی نہیں ملی'},
    'recipeRemoved': {'en': 'Recipe removed from saved recipes', 'ur': 'ریسیپی محفوظ شدہ فہرست سے ہٹا دی گئی'},
    'failedToRemoveRecipe': {'en': 'Failed to remove recipe', 'ur': 'ریسیپی ہٹانے میں ناکامی'},
    'likes': {'en': 'Likes', 'ur': 'پسند'},
    'missingIngredients': {'en': 'Missing ingredients', 'ur': 'غائب اجزاء'},
  };

  static String get(String key) {
    final locale = LocaleProvider().localeNotifier.value;
    final langCode = locale?.languageCode ?? 'en';
    return translations[key]?[langCode] ?? translations[key]?['en'] ?? key;
  }
}
