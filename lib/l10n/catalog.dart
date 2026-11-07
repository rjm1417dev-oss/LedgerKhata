/// Roman Urdu and Urdu wording for one English phrase.
class Entry {
  final String roman;
  final String urdu;
  const Entry(this.roman, this.urdu);
}

Entry _(String roman, String urdu) => Entry(roman, urdu);

/// Every phrase the app shows, keyed by its English text. A key containing
/// `{name}`-style placeholders is a template: it converts any English message
/// of that shape and keeps the values (names, amounts, dates) as they are.
///
/// Add a new phrase here and it is translated everywhere it is shown. A phrase
/// missing from this list is shown in English, and the catalog test fails for
/// any literal in the code that has no entry.
///
/// Wording rule: short, everyday words — Baqi, Jama, Khareedari, Hisab,
/// Tareekh — not accounting terms.
final Map<String, Entry> kCatalog = {
  // ── Navigation & titles ───────────────────────────────────────────────
  'Dashboard': _('Dashboard', 'ڈیش بورڈ'),
  'Khata': _('Khata', 'کھاتہ'),
  'Khatas': _('Khata', 'کھاتے'),
  'Items': _('Items', 'آئٹمز'),
  'Customers': _('Customers', 'گاہک'),
  'Settings': _('Settings', 'سیٹنگز'),
  'Khata Management': _('Khata Hisab', 'کھاتہ مینجمنٹ'),
  'Back': _('Wapas', 'واپس'),
  'Close': _('Band Karein', 'بند کریں'),
  'Cancel': _('Cancel', 'منسوخ کریں'),
  'Done': _('Ho Gaya', 'مکمل'),
  'Add': _('Add Karein', 'شامل کریں'),
  'View all': _('Sab Dekhein', 'سب دیکھیں'),
  'Delete': _('Delete', 'حذف کریں'),
  'OK': _('Theek Hai', 'ٹھیک ہے'),
  'Try again': _('Dobara Koshish Karein', 'دوبارہ کوشش کریں'),
  'Sign out': _('Sign Out', 'سائن آؤٹ'),
  'Sign in': _('Sign In', 'سائن اِن'),
  'Signing in…': _('Sign In Ho Raha Hai…', 'سائن اِن ہو رہا ہے…'),
  'Preparing…': _('Tayyar Ho Raha Hai…', 'تیار ہو رہا ہے…'),
  'Opening…': _('Khul Raha Hai…', 'کھل رہا ہے…'),
  'Language': _('Zubaan', 'زبان'),
  'Select language': _('Zubaan Chunein', 'زبان منتخب کریں'),

  // ── Login & register ──────────────────────────────────────────────────
  'Welcome back': _('Khush Aamdeed', 'خوش آمدید'),
  'Sign in to see your khatas, customers and items.': _(
    'Apne khata, customers aur items dekhne ke liye sign in karein.',
    'اپنے کھاتے، گاہک اور آئٹمز دیکھنے کے لیے سائن اِن کریں۔',
  ),
  'New here?': _('Naye Hain?', 'نئے ہیں؟'),
  'Email': _('Email', 'ای میل'),
  'you@example.com': _('you@example.com', 'you@example.com'),
  'Password': _('Password', 'پاس ورڈ'),
  'Your password': _('Apna password', 'آپ کا پاس ورڈ'),
  'Register your business': _(
    'Apna Karobar Register Karein',
    'اپنا کاروبار رجسٹر کریں',
  ),
  'Your khatas, customers and items stay private to your business account.': _(
    'Aap ke khata, customers aur items sirf aap ke account mein mehfooz rehte hain.',
    'آپ کے کھاتے، گاہک اور آئٹمز صرف آپ کے اکاؤنٹ میں محفوظ رہتے ہیں۔',
  ),
  'Already have an account?': _('Pehle se account hai?', 'پہلے سے اکاؤنٹ ہے؟'),
  'Business name': _('Karobar Ka Naam', 'کاروبار کا نام'),
  'e.g. Al-Noor Traders': _('Misaal: Al-Noor Traders', 'مثال: Al-Noor Traders'),
  'Owner name': _('Malik Ka Naam', 'مالک کا نام'),
  'Full name': _('Poora Naam', 'پورا نام'),
  'Phone number': _('Phone Number', 'فون نمبر'),
  '03XX XXXXXXX': _('03XX XXXXXXX', '03XX XXXXXXX'),
  'Business address (optional)': _(
    'Karobar Ka Pata (zaroori nahi)',
    'کاروبار کا پتہ (ضروری نہیں)',
  ),
  'Shop, street, city': _('Dukaan, gali, shehar', 'دکان، گلی، شہر'),
  'Business contact number (optional)': _(
    'Karobar Ka Contact Number (zaroori nahi)',
    'کاروبار کا رابطہ نمبر (ضروری نہیں)',
  ),
  'At least 6 characters': _('Kam az kam 6 harf', 'کم از کم 6 حروف'),
  'Create account': _('Account Banayein', 'اکاؤنٹ بنائیں'),
  'Creating account…': _('Account Ban Raha Hai…', 'اکاؤنٹ بن رہا ہے…'),

  // ── Validation ────────────────────────────────────────────────────────
  'Enter a phone number': _('Phone number likhein', 'فون نمبر لکھیں'),
  'Enter a valid phone number': _(
    'Sahi phone number likhein',
    'درست فون نمبر لکھیں',
  ),
  'Enter your email address': _('Apna email likhein', 'اپنا ای میل لکھیں'),
  'Enter a valid email address': _('Sahi email likhein', 'درست ای میل لکھیں'),
  'Enter a password': _('Password likhein', 'پاس ورڈ لکھیں'),
  'Enter your password': _('Apna password likhein', 'اپنا پاس ورڈ لکھیں'),
  'Password must be at least 6 characters': _(
    'Password kam az kam 6 harf ka hona chahiye',
    'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے',
  ),
  'Enter your business name': _(
    'Karobar ka naam likhein',
    'کاروبار کا نام لکھیں',
  ),
  'Enter the owner name': _('Malik ka naam likhein', 'مالک کا نام لکھیں'),
  'Enter the customer name': _('Customer ka naam likhein', 'گاہک کا نام لکھیں'),
  'Enter the item name': _('Item ka naam likhein', 'آئٹم کا نام لکھیں'),
  'Select a unit': _('Unit chunein', 'یونٹ منتخب کریں'),
  'Enter a price greater than 0': _(
    '0 se zyada qeemat likhein',
    '0 سے زیادہ قیمت لکھیں',
  ),
  'Enter a smaller price': _('Kam qeemat likhein', 'کم قیمت لکھیں'),
  'Enter an amount greater than 0': _(
    '0 se zyada raqam likhein',
    '0 سے زیادہ رقم لکھیں',
  ),
  'Enter your current password': _(
    'Maujooda password likhein',
    'موجودہ پاس ورڈ لکھیں',
  ),
  'Enter a new password': _('Naya password likhein', 'نیا پاس ورڈ لکھیں'),
  'New password must be different from current password': _(
    'Naya password purane se alag hona chahiye',
    'نیا پاس ورڈ پرانے سے مختلف ہونا چاہیے',
  ),
  'Confirm your new password': _(
    'Naya password dobara likhein',
    'نیا پاس ورڈ دوبارہ لکھیں',
  ),
  'Passwords do not match': _(
    'Password aapas mein nahi milte',
    'پاس ورڈ آپس میں نہیں ملتے',
  ),
  'Select a customer for this khata': _(
    'Is khata ke liye customer chunein',
    'اس کھاتے کے لیے گاہک منتخب کریں',
  ),
  'Select at least one item': _(
    'Kam az kam ek item chunein',
    'کم از کم ایک آئٹم منتخب کریں',
  ),
  'Discount and paid amount can’t be more than the items total ({total})': _(
    'Chhoot aur jama raqam items ke total se zyada nahi ho sakti ({total})',
    'رعایت اور جمع رقم آئٹمز کے کل سے زیادہ نہیں ہو سکتی ({total})',
  ),
  'Discount and paid amount can’t be more than the items total': _(
    'Chhoot aur jama raqam items ke total se zyada nahi ho sakti',
    'رعایت اور جمع رقم آئٹمز کے کل سے زیادہ نہیں ہو سکتی',
  ),
  'Can’t be more than the outstanding amount ({amount})': _(
    'Baqi raqam se zyada nahi ho sakti ({amount})',
    'بقایا رقم سے زیادہ نہیں ہو سکتی ({amount})',
  ),
  'Select the customer whose khata you are clearing': _(
    'Jis customer ka khata clear karna hai usay chunein',
    'جس گاہک کا کھاتہ کلیئر کرنا ہے اسے منتخب کریں',
  ),
  'The start date can’t be after the end date': _(
    'Shuru ki tareekh aakhri tareekh se baad ki nahi ho sakti',
    'شروع کی تاریخ آخری تاریخ کے بعد کی نہیں ہو سکتی',
  ),

  // ── Errors from the server ────────────────────────────────────────────
  'Please sign in again.': _('Dobara sign in karein.', 'دوبارہ سائن اِن کریں۔'),
  'No internet connection. Check your network and try again.': _(
    'Internet nahi hai. Network check karke dobara koshish karein.',
    'انٹرنیٹ نہیں ہے۔ نیٹ ورک چیک کر کے دوبارہ کوشش کریں۔',
  ),
  'Something went wrong. Please try again.': _(
    'Kuch masla ho gaya. Dobara koshish karein.',
    'کچھ مسئلہ ہو گیا۔ دوبارہ کوشش کریں۔',
  ),
  'An account with this email already exists. Sign in instead.': _(
    'Is email ka account pehle se mojood hai. Sign in karein.',
    'اس ای میل کا اکاؤنٹ پہلے سے موجود ہے۔ سائن اِن کریں۔',
  ),
  'Current password is incorrect.': _(
    'Maujooda password ghalat hai.',
    'موجودہ پاس ورڈ غلط ہے۔',
  ),
  'Your business profile is missing. Please register again.': _(
    'Aap ka karobar profile nahi mila. Dobara register karein.',
    'آپ کا کاروباری پروفائل نہیں ملا۔ دوبارہ رجسٹر کریں۔',
  ),
  'This email address was rejected. Please use a different, working email address.':
      _(
        'Yeh email qubool nahi hua. Koi aur chalta hua email istemal karein.',
        'یہ ای میل قبول نہیں ہوا۔ کوئی اور چلتا ہوا ای میل استعمال کریں۔',
      ),
  'Too many attempts. Wait a minute and try again.': _(
    'Bohat zyada koshishein. Ek minute ruk kar dobara karein.',
    'بہت زیادہ کوششیں۔ ایک منٹ رک کر دوبارہ کریں۔',
  ),
  'Wrong email or password.': _(
    'Email ya password ghalat hai.',
    'ای میل یا پاس ورڈ غلط ہے۔',
  ),
  'Confirm your email first, then sign in.': _(
    'Pehle apna email confirm karein, phir sign in karein.',
    'پہلے اپنا ای میل تصدیق کریں، پھر سائن اِن کریں۔',
  ),
  'This can’t be deleted — it’s still used in existing khatas.': _(
    'Yeh delete nahi ho sakta — yeh maujooda khatas mein istemal hai.',
    'یہ حذف نہیں ہو سکتا — یہ موجودہ کھاتوں میں استعمال ہے۔',
  ),
  'That payment is more than the remaining amount.': _(
    'Yeh raqam baqi raqam se zyada hai.',
    'یہ رقم بقایا رقم سے زیادہ ہے۔',
  ),
  'You don’t have permission to do that.': _(
    'Aap ko iski ijazat nahi hai.',
    'آپ کو اس کی اجازت نہیں ہے۔',
  ),
  'The database isn’t set up yet. Run the Supabase migration first.': _(
    'Database abhi tayyar nahi hai. Pehle Supabase migration chalayein.',
    'ڈیٹا بیس ابھی تیار نہیں ہے۔ پہلے Supabase migration چلائیں۔',
  ),
  'Logo storage isn’t set up yet. Run the Supabase migration first.': _(
    'Logo storage abhi tayyar nahi hai. Pehle Supabase migration chalayein.',
    'لوگو اسٹوریج ابھی تیار نہیں ہے۔ پہلے Supabase migration چلائیں۔',
  ),
  'Couldn’t upload the logo. Please try again.': _(
    'Logo upload nahi ho saka. Dobara koshish karein.',
    'لوگو اپ لوڈ نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
  ),
  'Select at least one item.': _(
    'Kam az kam ek item chunein.',
    'کم از کم ایک آئٹم منتخب کریں۔',
  ),
  'Customer not found': _('Customer nahi mila', 'گاہک نہیں ملا'),
  'One or more items were not found': _(
    'Ek ya zyada items nahi mile',
    'ایک یا زیادہ آئٹمز نہیں ملے',
  ),
  'Enter a quantity greater than 0 for every item': _(
    'Har item ki miqdaar 0 se zyada likhein',
    'ہر آئٹم کی مقدار 0 سے زیادہ لکھیں',
  ),
  'Enter a payment amount greater than 0': _(
    '0 se zyada raqam likhein',
    '0 سے زیادہ رقم لکھیں',
  ),
  'This customer has no outstanding khata': _(
    'Is customer ka koi khata baqi nahi',
    'اس گاہک کا کوئی کھاتہ باقی نہیں',
  ),
  'That payment is more than the outstanding amount ({amount})': _(
    'Yeh raqam baqi raqam se zyada hai ({amount})',
    'یہ رقم بقایا رقم سے زیادہ ہے ({amount})',
  ),
  'Couldn’t open the photo picker.': _(
    'Photo picker nahi khul saka.',
    'فوٹو پکر نہیں کھل سکا۔',
  ),
  'Couldn’t load your data': _(
    'Aap ka data load nahi ho saka',
    'آپ کا ڈیٹا لوڈ نہیں ہو سکا',
  ),
  'The app couldn’t find your Supabase project details.': _(
    'App ko aap ke Supabase project ki tafseel nahi mili.',
    'ایپ کو آپ کے Supabase پروجیکٹ کی تفصیل نہیں ملی۔',
  ),
  'Connect Supabase': _('Supabase Jorein', 'Supabase جوڑیں'),
  'Couldn’t create the report. Please try again.': _(
    'Report nahi ban saki. Dobara koshish karein.',
    'رپورٹ نہیں بن سکی۔ دوبارہ کوشش کریں۔',
  ),

  // ── Success & info messages ───────────────────────────────────────────
  'Logo updated': _('Logo badal diya gaya', 'لوگو تبدیل ہو گیا'),
  'Business details updated': _(
    'Karobar ki tafseel update ho gayi',
    'کاروبار کی تفصیل اپ ڈیٹ ہو گئی',
  ),
  'Password updated successfully': _(
    'Password kamyabi se badal gaya',
    'پاس ورڈ کامیابی سے تبدیل ہو گیا',
  ),
  'Khata saved for {name}': _(
    '{name} ka khata save ho gaya',
    '{name} کا کھاتہ محفوظ ہو گیا',
  ),
  'Khata cleared for {name}': _(
    '{name} ka khata clear ho gaya',
    '{name} کا کھاتہ کلیئر ہو گیا',
  ),
  '{amount} received from {name}': _(
    '{name} se {amount} jama hue',
    '{name} سے {amount} جمع ہوئے',
  ),
  '{name} added and selected': _(
    '{name} add ho gaya aur chun liya gaya',
    '{name} شامل ہو گیا اور منتخب کر لیا گیا',
  ),
  '{name} added': _('{name} add ho gaya', '{name} شامل ہو گیا'),
  '{name} updated': _('{name} update ho gaya', '{name} اپ ڈیٹ ہو گیا'),
  '{name} deleted': _('{name} delete ho gaya', '{name} حذف ہو گیا'),
  'Khata saved, but {name}’s phone number isn’t valid for WhatsApp.': _(
    'Khata save ho gaya, lekin {name} ka phone number WhatsApp ke liye sahi nahi.',
    'کھاتہ محفوظ ہو گیا، لیکن {name} کا فون نمبر واٹس ایپ کے لیے درست نہیں۔',
  ),
  'Khata saved, but WhatsApp couldn’t be opened.': _(
    'Khata save ho gaya, lekin WhatsApp nahi khul saka.',
    'کھاتہ محفوظ ہو گیا، لیکن واٹس ایپ نہیں کھل سکا۔',
  ),
  '{name}’s phone number isn’t valid for WhatsApp. Edit the customer and try again.': _(
    '{name} ka phone number WhatsApp ke liye sahi nahi. Customer edit karke dobara koshish karein.',
    '{name} کا فون نمبر واٹس ایپ کے لیے درست نہیں۔ گاہک میں ترمیم کر کے دوبارہ کوشش کریں۔',
  ),
  'Couldn’t open WhatsApp on this device.': _(
    'Is phone par WhatsApp nahi khul saka.',
    'اس فون پر واٹس ایپ نہیں کھل سکا۔',
  ),

  // ── Dashboard ─────────────────────────────────────────────────────────
  'Recent khatas': _('Haal Ke Khata', 'حالیہ کھاتے'),
  'Clear Khata': _('Khata Clear Karein', 'کھاتہ کلیئر کریں'),
  'New Khata': _('Naya Khata', 'نیا کھاتہ'),
  'Export Reports': _('Reports Export Karein', 'رپورٹس ایکسپورٹ کریں'),
  'No khatas yet': _('Abhi Koi Khata Nahi', 'ابھی کوئی کھاتہ نہیں'),
  'Create your first khata to record items, discount and payments for a customer.': _(
    'Customer ke items, chhoot aur jama raqam likhne ke liye apna pehla khata banayein.',
    'گاہک کے آئٹمز، رعایت اور جمع رقم لکھنے کے لیے اپنا پہلا کھاتہ بنائیں۔',
  ),

  // ── Khata list / add khata ────────────────────────────────────────────
  'No khatas that month.': _(
    'Us mahine koi khata nahi.',
    'اس مہینے کوئی کھاتہ نہیں۔',
  ),
  'Select customer': _('Customer Chunein', 'گاہک منتخب کریں'),
  'Choose a customer': _('Customer chunein', 'گاہک منتخب کریں'),
  'No customers yet. Tap + to add one.': _(
    'Abhi koi customer nahi. + dabayein aur add karein.',
    'ابھی کوئی گاہک نہیں۔ + دبائیں اور شامل کریں۔',
  ),
  'Tap to select multiple': _(
    'Ek se zyada chunne ke liye dabayein',
    'ایک سے زیادہ منتخب کرنے کے لیے دبائیں',
  ),
  'No items match “{query}”': _(
    '“{query}” se koi item nahi milta',
    '“{query}” سے کوئی آئٹم نہیں ملتا',
  ),
  '{count} selected · {total}': _(
    '{count} chune gaye · {total}',
    '{count} منتخب · {total}',
  ),
  'Selected items': _('Chune Hue Items', 'منتخب آئٹمز'),
  'No items selected yet': _(
    'Abhi koi item nahi chuna',
    'ابھی کوئی آئٹم منتخب نہیں',
  ),
  'Search above and tap items to add them.': _(
    'Upar dhoondein aur items dabayein.',
    'اوپر تلاش کریں اور آئٹمز دبائیں۔',
  ),
  'Items total': _('Items Ka Total', 'آئٹمز کا کل'),
  'Total items amount': _('Items Ki Kul Raqam', 'آئٹمز کی کل رقم'),
  'Remaining': _('Baqi', 'باقی'),
  'Add customer': _('Customer Add Karein', 'گاہک شامل کریں'),
  'Back to Khata': _('Khata Par Wapas', 'کھاتے پر واپس'),
  'Customer': _('Customer', 'گاہک'),
  'Add new customer': _('Naya Customer Add Karein', 'نیا گاہک شامل کریں'),
  'Search items': _('Items Dhoondein', 'آئٹمز تلاش کریں'),
  'Search by item name': _(
    'Item ke naam se dhoondein',
    'آئٹم کے نام سے تلاش کریں',
  ),
  'Payment': _('Jama Raqam', 'جمع رقم'),
  'Discount': _('Chhoot', 'رعایت'),
  'Paid amount': _('Jama Raqam', 'جمع رقم'),
  'Remaining amount': _('Baqi Raqam', 'بقایا رقم'),
  'Auto-calculated: Total items amount − Discount − Paid amount': _(
    'Khud hisab: Items ki raqam − Chhoot − Jama raqam',
    'خود حساب: آئٹمز کی رقم − رعایت − جمع رقم',
  ),
  'Save & Share': _('Save Aur Share Karein', 'محفوظ کریں اور شیئر کریں'),
  'Save Khata': _('Khata Save Karein', 'کھاتہ محفوظ کریں'),
  'Customer name': _('Customer Ka Naam', 'گاہک کا نام'),
  'Save customer': _('Customer Save Karein', 'گاہک محفوظ کریں'),
  'Save changes': _('Tabdeeli Save Karein', 'تبدیلی محفوظ کریں'),
  'Save item': _('Item Save Karein', 'آئٹم محفوظ کریں'),

  // ── Clear khata ───────────────────────────────────────────────────────
  'Total outstanding': _('Kul Baqi Raqam', 'کل بقایا رقم'),
  'Amount received': _('Wasool Hui Raqam', 'وصول شدہ رقم'),
  'No customers owe anything': _(
    'Kisi customer ki raqam baqi nahi',
    'کسی گاہک کی رقم باقی نہیں',
  ),

  // ── Customers ─────────────────────────────────────────────────────────
  'Edit customer': _('Customer Edit Karein', 'گاہک میں ترمیم'),
  'Edit {name}': _('{name} Edit Karein', '{name} میں ترمیم'),
  'Back to Customers': _('Customers Par Wapas', 'گاہکوں پر واپس'),
  'Export Report': _('Report Export Karein', 'رپورٹ ایکسپورٹ کریں'),
  'Add a khata for {name} to start tracking what they owe.': _(
    '{name} ka khata banayein taake pata chale unki kitni raqam baqi hai.',
    '{name} کا کھاتہ بنائیں تاکہ پتا چلے ان کی کتنی رقم باقی ہے۔',
  ),
  'Show all time': _('Sara Record Dikhayein', 'سارا ریکارڈ دکھائیں'),
  'No activity that month.': _(
    'Us mahine koi entry nahi.',
    'اس مہینے کوئی اندراج نہیں۔',
  ),
  'No customers yet': _('Abhi Koi Customer Nahi', 'ابھی کوئی گاہک نہیں'),
  'Add customers to start creating khatas for them.': _(
    'Customers add karein taake unke khata ban saken.',
    'گاہک شامل کریں تاکہ ان کے کھاتے بن سکیں۔',
  ),
  'Can’t delete {name}': _(
    '{name} Delete Nahi Ho Sakta',
    '{name} حذف نہیں ہو سکتا',
  ),
  'Delete {name}?': _('{name} Delete Karein?', '{name} حذف کریں؟'),
  'Delete {name}': _('{name} Delete Karein', '{name} حذف کریں'),
  'Remove {name}': _('{name} Hataein', '{name} ہٹائیں'),
  'This can’t be undone.': _(
    'Yeh wapas nahi ho sakta.',
    'یہ واپس نہیں ہو سکتا۔',
  ),
  '1 khata': _('1 khata', '1 کھاتہ'),
  '{n} khatas': _('{n} khata', '{n} کھاتے'),
  '1 customer': _('1 customer', '1 گاہک'),
  '{n} customers': _('{n} customers', '{n} گاہک'),
  '1 item': _('1 item', '1 آئٹم'),
  '{n} items': _('{n} items', '{n} آئٹمز'),
  'Customer not found.': _('Customer nahi mila.', 'گاہک نہیں ملا۔'),
  'Pending on {a} of {b} khatas': _(
    '{b} mein se {a} khata baqi hain',
    '{b} میں سے {a} کھاتے باقی ہیں',
  ),
  'Total remaining': _('Kul Baqi Raqam', 'کل بقایا رقم'),
  'Total billed': _('Kul Bill', 'کل بل'),
  'Received': _('Wasool Hua', 'وصول ہوا'),
  'Opened {when}': _('Khula: {when}', 'کھلا: {when}'),
  '{date} · 1 item': _('{date} · 1 item', '{date} · 1 آئٹم'),
  '{date} · {n} items': _('{date} · {n} items', '{date} · {n} آئٹمز'),
  'Send {name} this khata on WhatsApp': _(
    '{name} ko yeh khata WhatsApp par bhejein',
    '{name} کو یہ کھاتہ واٹس ایپ پر بھیجیں',
  ),
  '{n} khata': _('{n} khata', '{n} کھاتہ'),

  '{name} has 1 khata on record. Delete that khata first if you still want to remove this customer.': _(
    '{name} ka 1 khata maujood hai. Customer hatane se pehle woh khata delete karein.',
    '{name} کا 1 کھاتہ موجود ہے۔ گاہک ہٹانے سے پہلے وہ کھاتہ حذف کریں۔',
  ),
  '{name} has {count} khatas on record. Delete those khatas first if you still want to remove this customer.': _(
    '{name} ke {count} khata maujood hain. Customer hatane se pehle woh khata delete karein.',
    '{name} کے {count} کھاتے موجود ہیں۔ گاہک ہٹانے سے پہلے وہ کھاتے حذف کریں۔',
  ),
  'Used in 1 khata — that record keeps "{name}"\'s name, price and unit. This can’t be undone.': _(
    '1 khata mein istemal hua — woh record "{name}" ka naam, qeemat aur unit mehfooz rakhta hai. Yeh wapas nahi ho sakta.',
    '1 کھاتے میں استعمال ہوا — وہ ریکارڈ "{name}" کا نام، قیمت اور یونٹ محفوظ رکھتا ہے۔ یہ واپس نہیں ہو سکتا۔',
  ),
  'Used in {n} khatas — those records keep "{name}"\'s name, price and unit. This can’t be undone.': _(
    '{n} khata mein istemal hua — woh record "{name}" ka naam, qeemat aur unit mehfooz rakhte hain. Yeh wapas nahi ho sakta.',
    '{n} کھاتوں میں استعمال ہوا — وہ ریکارڈ "{name}" کا نام، قیمت اور یونٹ محفوظ رکھتے ہیں۔ یہ واپس نہیں ہو سکتا۔',
  ),
  'Password must be at least 6 characters.': _(
    'Password kam az kam 6 harf ka hona chahiye.',
    'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے۔',
  ),
  'Enter a valid email address.': _(
    'Sahi email likhein.',
    'درست ای میل لکھیں۔',
  ),

  // ── Items ─────────────────────────────────────────────────────────────
  'Add item': _('Item Add Karein', 'آئٹم شامل کریں'),
  'Edit item': _('Item Edit Karein', 'آئٹم میں ترمیم'),
  'No items yet': _('Abhi Koi Item Nahi', 'ابھی کوئی آئٹم نہیں'),
  'Add the items you sell with their price.': _(
    'Jo items bechte hain unki qeemat ke saath add karein.',
    'جو آئٹمز بیچتے ہیں ان کی قیمت کے ساتھ شامل کریں۔',
  ),
  'Item name': _('Item Ka Naam', 'آئٹم کا نام'),
  'e.g. Sugar': _('Misaal: Cheeni', 'مثال: چینی'),
  'Unit': _('Unit', 'یونٹ'),
  'Select unit': _('Unit chunein', 'یونٹ منتخب کریں'),
  'Price': _('Qeemat', 'قیمت'),
  'Price per {unit}': _('Ek {unit} ki qeemat', 'فی {unit} قیمت'),
  '{price} / {unit}': _('{price} / {unit}', '{price} / {unit}'),
  'Read only': _('Sirf Parhne Ke Liye', 'صرف پڑھنے کے لیے'),
  'Show password': _('Password Dikhayein', 'پاس ورڈ دکھائیں'),
  'Hide password': _('Password Chhupayein', 'پاس ورڈ چھپائیں'),

  // ── Settings ──────────────────────────────────────────────────────────
  'BUSINESS': _('KAROBAR', 'کاروبار'),
  'SECURITY': _('HIFAZAT', 'حفاظت'),
  'Business account': _('Karobar Account', 'کاروباری اکاؤنٹ'),
  'Change your account password': _(
    'Apne account ka password badlein',
    'اپنے اکاؤنٹ کا پاس ورڈ تبدیل کریں',
  ),
  'Enter your current password to verify your identity, then choose a new password.': _(
    'Apni pehchaan ke liye maujooda password likhein, phir naya password chunein.',
    'اپنی شناخت کے لیے موجودہ پاس ورڈ لکھیں، پھر نیا پاس ورڈ چنیں۔',
  ),
  'Edit business': _('Karobar Edit Karein', 'کاروبار میں ترمیم'),
  'Update password': _('Password Badlein', 'پاس ورڈ تبدیل کریں'),
  'Edit business details': _(
    'Karobar Ki Tafseel Edit Karein',
    'کاروبار کی تفصیل میں ترمیم',
  ),
  'Update': _('Update Karein', 'اپ ڈیٹ کریں'),
  'Change business logo': _(
    'Karobar Ka Logo Badlein',
    'کاروبار کا لوگو تبدیل کریں',
  ),
  'Your shop name': _('Aap ki dukaan ka naam', 'آپ کی دکان کا نام'),
  'Address (optional)': _('Pata (zaroori nahi)', 'پتہ (ضروری نہیں)'),
  'Shop address': _('Dukaan ka pata', 'دکان کا پتہ'),
  'Public contact number (optional)': _(
    'Aam Contact Number (zaroori nahi)',
    'عام رابطہ نمبر (ضروری نہیں)',
  ),
  'Current password': _('Maujooda Password', 'موجودہ پاس ورڈ'),
  'Your current password': _(
    'Aap ka maujooda password',
    'آپ کا موجودہ پاس ورڈ',
  ),
  'New password': _('Naya Password', 'نیا پاس ورڈ'),
  'Confirm new password': _(
    'Naya Password Dobara Likhein',
    'نیا پاس ورڈ دوبارہ لکھیں',
  ),
  'Re-enter your new password': _(
    'Naya password dobara likhein',
    'نیا پاس ورڈ دوبارہ لکھیں',
  ),
  'Address': _('Pata', 'پتہ'),
  'Public contact number': _('Aam Contact Number', 'عام رابطہ نمبر'),
  'Not set': _('Muqarrar Nahi', 'مقرر نہیں'),

  'Khata Transactions': _('Khata Ki Entries', 'کھاتے کے اندراجات'),
  'Report Summary': _('Report Ka Khulasa', 'رپورٹ کا خلاصہ'),
  'Item Details': _('Items Ki Tafseel', 'آئٹمز کی تفصیل'),
  'Customer Balances': _('Customers Ki Baqi Raqam', 'گاہکوں کی بقایا رقم'),
  'Transaction History': _('Hisab Ki Tafseel', 'حساب کی تفصیل'),
  'Daily Summary': _('Roz Ka Hisab', 'روزانہ کا حساب'),

  // ── Reports & export screen ───────────────────────────────────────────
  'All customers': _('Tamam Customers', 'تمام گاہک'),
  'Date range (khata opened)': _(
    'Tareekh (khata khulne ki)',
    'تاریخ (کھاتہ کھلنے کی)',
  ),
  'Payment status': _('Jama Ki Surat', 'جمع کی صورت'),
  'Fix the date range to see a preview.': _(
    'Preview dekhne ke liye tareekhein theek karein.',
    'پیش نظارہ دیکھنے کے لیے تاریخیں درست کریں۔',
  ),
  'No Khata records match these filters.': _(
    'In filters se koi khata nahi milta.',
    'ان فلٹرز سے کوئی کھاتہ نہیں ملتا۔',
  ),
  'Report type': _('Report Ki Qism', 'رپورٹ کی قسم'),
  'All Khatas': _('Tamam Khata', 'تمام کھاتے'),
  'Pending Khatas': _('Baqi Khata', 'باقی کھاتے'),
  'Cleared Khatas': _('Clear Khata', 'کلیئر کھاتے'),
  'File format': _('File Ki Qism', 'فائل کی قسم'),
  'Filters': _('Record Dhoondein', 'ریکارڈ تلاش کریں'),
  'From': _('Se', 'سے'),
  'To': _('Tak', 'تک'),
  'Preview': _('Pesh Nazara', 'پیش نظارہ'),
  'Export {format}': _('{format} Export Karein', '{format} ایکسپورٹ کریں'),
  'Clear {label} date': _(
    '{label} ki tareekh hataein',
    '{label} کی تاریخ ہٹائیں',
  ),
  'Choose {label} date': _(
    '{label} ki tareekh chunein',
    '{label} کی تاریخ منتخب کریں',
  ),
  'Start date': _('Shuru Ki Tareekh', 'شروع کی تاریخ'),
  'End date': _('Aakhri Tareekh', 'آخری تاریخ'),
  'Print & share': _('Print Aur Share Karein', 'پرنٹ اور شیئر کریں'),
  'Sort & analyse': _('Tarteeb Aur Tajziya', 'ترتیب اور تجزیہ'),
  'Pending Khatas Report': _('Baqi Khata Ki Report', 'باقی کھاتوں کی رپورٹ'),
  'Cleared Khatas Report': _('Clear Khata Ki Report', 'کلیئر کھاتوں کی رپورٹ'),
  'All Khatas Report': _('Tamam Khata Ki Report', 'تمام کھاتوں کی رپورٹ'),
  'Khata Report': _('Khata Report', 'کھاتہ رپورٹ'),
  'All dates': _('Tamam Tareekhein', 'تمام تاریخیں'),
  'All statuses': _('Tamam Surtein', 'تمام صورتیں'),
  'From {date}': _('{date} Se', '{date} سے'),
  'Up to {date}': _('{date} Tak', '{date} تک'),
  'Pending': _('Baqi', 'باقی'),
  'Partially Paid': _('Kuch Jama', 'کچھ جمع'),
  'Cleared': _('Clear', 'کلیئر'),
  'Shop': _('Dukaan', 'دکان'),
  'Date range: {value}': _('Tareekh: {value}', 'تاریخ: {value}'),
  'Payment status: {value}': _(
    'Jama ki surat: {value}',
    'جمع کی صورت: {value}',
  ),
  'Customer: {value}': _('Customer: {value}', 'گاہک: {value}'),
  'Generated: {value}': _('Banayi Gayi: {value}', 'تیار کردہ: {value}'),
  'Report generated': _('Report Banne Ka Waqt', 'رپورٹ بننے کا وقت'),
  'Date range': _('Tareekh', 'تاریخ'),
  'Business phone': _('Karobar Ka Phone', 'کاروبار کا فون'),
  'Payment status filter': _('Jama Ki Surat Ka Filter', 'جمع کی صورت کا فلٹر'),
  'Totals': _('Total', 'کل'),
  'Total transactions': _('Kul Entries', 'کل اندراجات'),
  'Total sales on credit': _('Udhaar Par Kul Bikri', 'ادھار پر کل فروخت'),
  'Total discounts': _('Kul Chhoot', 'کل رعایت'),
  'Grand total (after discount)': _('Chhoot Ke Baad Kul', 'رعایت کے بعد کل'),
  'Total payments recorded': _('Kul Jama Raqam', 'کل جمع رقم'),
  'Total outstanding balance': _('Kul Baqi Raqam', 'کل بقایا رقم'),
  'Purchase transactions in range': _(
    'Is Dauraan Khareedari Ki Entries',
    'اس دوران خریداری کے اندراجات',
  ),
  'Payment transactions in range': _(
    'Is Dauraan Jama Ki Entries',
    'اس دوران جمع کے اندراجات',
  ),
  'Pending transactions': _('Baqi Entries', 'باقی اندراجات'),
  'Partially paid transactions': _('Kuch Jama Entries', 'کچھ جمع اندراجات'),
  'Cleared transactions': _('Clear Entries', 'کلیئر اندراجات'),
  'No Khata records match the selected filters.': _(
    'Chune gaye filters se koi khata nahi milta.',
    'منتخب فلٹرز سے کوئی کھاتہ نہیں ملتا۔',
  ),
  'Transaction ID': _('Entry ID', 'اندراج آئی ڈی'),
  'Date': _('Tareekh', 'تاریخ'),
  'Day': _('Din', 'دن'),
  'Phone': _('Phone', 'فون'),
  'Item details': _('Items Ki Tafseel', 'آئٹمز کی تفصیل'),
  'Total quantity': _('Kul Miqdaar', 'کل مقدار'),
  'Subtotal': _('Items Ka Total', 'آئٹمز کا کل'),
  'Grand total': _('Kul Raqam', 'کل رقم'),
  'Amount paid': _('Jama Raqam', 'جمع رقم'),
  'Remaining balance': _('Baqi Raqam', 'باقی رقم'),
  'Quantity': _('Miqdaar', 'مقدار'),
  'Unit price': _('Ek Unit Ki Qeemat', 'ایک یونٹ کی قیمت'),
  'Item subtotal': _('Item Ka Total', 'آئٹم کا کل'),
  'Date & time': _('Tareekh Aur Waqt', 'تاریخ اور وقت'),
  'Transactions': _('Entries', 'اندراجات'),
  'Outstanding balance': _('Baqi Raqam', 'بقایا رقم'),
  'Payment date & time': _('Jama Ki Tareekh Aur Waqt', 'جمع کی تاریخ اور وقت'),
  'Type': _('Qism', 'قسم'),
  'Amount': _('Raqam', 'رقم'),
  'Payment ref': _('Jama Ref', 'جمع ریف'),
  'Time': _('Waqt', 'وقت'),
  'Items (qty unit × price)': _(
    'Items (miqdaar unit × qeemat)',
    'آئٹمز (مقدار یونٹ × قیمت)',
  ),
  'Purchase amount': _('Khareedari Ki Raqam', 'خریداری کی رقم'),
  'Payment received': _('Jama Raqam', 'جمع رقم'),
  'Balance after': _('Ab Baqi', 'اب بقایا'),
  'Purchases (count)': _('Khareedari (tadaad)', 'خریداری (تعداد)'),
  'Payments (count)': _('Jama (tadaad)', 'جمع (تعداد)'),
  'Purchased': _('Khareedari', 'خریداری'),
  'Closing balance': _('Din Ke Aakhir Mein Baqi', 'دن کے آخر میں بقایا'),
  'Paid with purchases': _('Khareedari Ke Saath Jama', 'خریداری کے ساتھ جمع'),
  'Transaction history': _('Hisab Ki Tafseel', 'حساب کی تفصیل'),
  'Khata transactions': _('Khata Ki Entries', 'کھاتے کے اندراجات'),
  'Summary': _('Khulasa', 'خلاصہ'),
  'Customer balances': _('Customers Ki Baqi Raqam', 'گاہکوں کی بقایا رقم'),
  'Final summary': _('Aakhri Khulasa', 'آخری خلاصہ'),
  'Items subtotal': _('Items Ka Total', 'آئٹمز کا کل'),
  'Total amount paid': _('Kul Jama Raqam', 'کل جمع رقم'),
  'Pending / Partial / Cleared': _(
    'Baqi / Kuch Jama / Clear',
    'باقی / کچھ جمع / کلیئر',
  ),
  'Page {n} of {total}': _('Safha {n} / {total}', 'صفحہ {n} / {total}'),
  'Phone: {value}': _('Phone: {value}', 'فون: {value}'),
  'Paid': _('Jama', 'جمع'),
  'Total': _('Total', 'کل'),
  'Item': _('Item', 'آئٹم'),
  'Qty': _('Miqdaar', 'مقدار'),
  'Outstanding': _('Baqi', 'باقی'),
  'Total paid': _('Kul Jama', 'کل جمع'),
  'Payments:': _('Jama:', 'جمع:'),
  '{n} transaction exported ({a} pending, {b} partially paid, {c} cleared).': _(
    '{n} entry export hui ({a} baqi, {b} kuch jama, {c} clear).',
    '{n} اندراج ایکسپورٹ ہوا ({a} باقی، {b} کچھ جمع، {c} کلیئر)۔',
  ),
  '{n} transactions exported ({a} pending, {b} partially paid, {c} cleared).':
      _(
        '{n} entries export hui ({a} baqi, {b} kuch jama, {c} clear).',
        '{n} اندراجات ایکسپورٹ ہوئے ({a} باقی، {b} کچھ جمع، {c} کلیئر)۔',
      ),
  'Every purchase and payment with its exact time, oldest first. Times are shop time (Pakistan, UTC+5).': _(
    'Har khareedari aur jama raqam apne waqt ke saath, purani pehle. Waqt Pakistan ka hai (UTC+5).',
    'ہر خریداری اور جمع رقم اپنے وقت کے ساتھ، پرانی پہلے۔ وقت پاکستان کا ہے (UTC+5)۔',
  ),
  'Paid with purchases: {amount}': _(
    'Khareedari ke saath jama: {amount}',
    'خریداری کے ساتھ جمع: {amount}',
  ),
  'Discount − {amount}': _('Chhoot − {amount}', 'رعایت − {amount}'),
  'Received {amount}': _('Wasool {amount}', 'وصول {amount}'),
  '{name} ({phone})': _('{name} ({phone})', '{name} ({phone})'),
  '{name}  ·  {phone}  —  {p}, {q}': _(
    '{name}  ·  {phone}  —  {p}, {q}',
    '{name}  ·  {phone}  —  {p}, {q}',
  ),
  '{purchases} purchases, {payments} payments': _(
    '{purchases} khareedari, {payments} jama',
    '{purchases} خریداری، {payments} جمع',
  ),
  '{d}  ·  {p}, {q}': _('{d}  ·  {p}, {q}', '{d}  ·  {p}, {q}'),

  // ── WhatsApp messages ─────────────────────────────────────────────────
  'Send on WhatsApp': _('WhatsApp Par Bhejein', 'واٹس ایپ پر بھیجیں'),
  'Not now': _('Abhi Nahi', 'ابھی نہیں'),
  'Send khata statement': _('Khata Ka Hisab Bhejein', 'کھاتے کا حساب بھیجیں'),
  'Send this to {name} ({phone}).': _(
    'Yeh {name} ({phone}) ko bhejein.',
    'یہ {name} ({phone}) کو بھیجیں۔',
  ),
  'Khata entry': _('Khata Entry', 'کھاتے کا اندراج'),
  'Khata statement': _('Khata Ka Hisab', 'کھاتے کا حساب'),
  'Dear {name},': _('Muhtaram {name},', 'محترم {name}،'),
  'Here is your khata entry of {when}:': _(
    '{when} ki aap ke khata ki entry:',
    '{when} کے آپ کے کھاتے کا اندراج:',
  ),
  'Your khata opened on {when}:': _(
    'Aap ka khata {when} ko khula:',
    'آپ کا کھاتہ {when} کو کھلا:',
  ),
  'Items total: {amount}': _(
    'Items ka total: {amount}',
    'آئٹمز کا کل: {amount}',
  ),
  'Discount: −{amount}': _('Chhoot: −{amount}', 'رعایت: −{amount}'),
  'Paid: {amount}': _('Jama: {amount}', 'جمع: {amount}'),
  'This entry: {amount}': _('Is entry ka: {amount}', 'اس اندراج کا: {amount}'),
  '*Total balance due on your khata: {amount}*': _(
    '*Aap ke khata ki kul baqi raqam: {amount}*',
    '*آپ کے کھاتے کی کل بقایا رقم: {amount}*',
  ),
  '*Your khata is fully settled.*': _(
    '*Aap ka khata poora clear hai.*',
    '*آپ کا کھاتہ پورا کلیئر ہے۔*',
  ),
  '*Balance due: {amount}*': _(
    '*Baqi raqam: {amount}*',
    '*بقایا رقم: {amount}*',
  ),
  'Thank you!': _('Shukriya!', 'شکریہ!'),

  // ── Badges, cards, misc ───────────────────────────────────────────────
  'Settled': _('Clear', 'کلیئر'),
  'All time': _('Sara Record', 'سارا ریکارڈ'),
  '{amount} due': _('{amount} Baqi', '{amount} باقی'),

  // ── Payment method ────────────────────────────────────────────────────
  'Payment method': _('Jama Karne Ka Tareeqa', 'جمع کرنے کا طریقہ'),
  'Cash': _('Cash', 'نقد'),
  'Online': _('Online', 'آن لائن'),
  'Choose Cash or Online as the payment method': _('Cash ya Online chunein', 'نقد یا آن لائن منتخب کریں'),
  'Not selected': _('Muntakhib Nahi', 'منتخب نہیں'),

  // ── Filters ───────────────────────────────────────────────────────────
  'Clear all filters': _('Sab Filter Hataein', 'تمام فلٹر ہٹائیں'),
  'Clear {label}': _('{label} Hataein', '{label} ہٹائیں'),
  'Select date': _('Tareekh chunein', 'تاریخ منتخب کریں'),
  '{n} selected': _('{n} chune gaye', '{n} منتخب'),

  // ── Ledger (customer history) ─────────────────────────────────────────
  'Account history': _('Hisab Ki Tafseel', 'حساب کی تفصیل'),
  'Purchase': _('Khareedari', 'خریداری'),
  'Purchases': _('Khareedari', 'خریداری'),
  'Payments': _('Jama Raqam', 'جمع رقم'),
  'Paid with purchase': _('Khareedari Ke Saath Jama', 'خریداری کے ساتھ جمع'),
  'Balance now': _('Ab Baqi', 'اب بقایا'),
  'Clear': _('Clear', 'کلیئر'),
  'each': _('ek', 'فی'),
  'Bought': _('Khareedari', 'خریداری'),
  'End of day': _('Din Ke Aakhir Mein Baqi', 'دن کے آخر میں بقایا'),
  'All': _('Sab', 'سب'),
  'Show older days': _('Purani Tareekhein Dikhayein', 'پرانی تاریخیں دکھائیں'),
  'No entries yet': _('Abhi Koi Entry Nahi', 'ابھی کوئی اندراج نہیں'),
  'No entries for this filter': _(
    'Is Filter Mein Koi Entry Nahi',
    'اس فلٹر میں کوئی اندراج نہیں',
  ),
  'Show fewer': _('Kam Dikhayein', 'کم دکھائیں'),
  'Show all {n} items': _('Saray {n} Items Dekhein', 'تمام {n} آئٹمز دیکھیں'),
  '{n} purchase': _('{n} Khareedari', '{n} خریداری'),
  '{n} purchases': _('{n} Khareedari', '{n} خریداری'),
  '{n} payment': _('{n} Jama', '{n} جمع'),
  '{n} payments': _('{n} Jama', '{n} جمع'),
};
