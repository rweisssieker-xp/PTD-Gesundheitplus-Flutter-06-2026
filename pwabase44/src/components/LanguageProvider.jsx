import React, { createContext, useContext, useState, useEffect } from 'react';
import { base44 } from "@/api/base44Client";

const translations = {
  de: {
    welcome: "Willkommen",
    welcomeMessage: "Ihre persönliche Gesundheitsakte",
    mainMenu: "Hauptmenü",
    allAreas: "Alle Bereiche",
    open: "Öffnen",
    scanDocument: "Dokument scannen",
    readAloud: "Vorlesen",
    setupLater: "Später einrichten",
    setupNow: "Jetzt einrichten",
    welcomeOnboarding: "Willkommen bei Gesundheit Plus!",
    onboardingMessage: "Lassen Sie uns gemeinsam Ihre persönliche Gesundheitsakte einrichten. Dies dauert nur wenige Minuten und kann auch per Sprache erfolgen.",
    anamnesis: "Anamnese",
    anamnesisSubtitle: "Krankengeschichte",
    anamnesisDesc: "Ihre medizinische Vorgeschichte",
    healthcare: "Heilberufe",
    healthcareSubtitle: "Ärzte & Behandler",
    healthcareDesc: "Alle Ihre Ärzte und Therapeuten",
    treatmentHistory: "Behandlungshistorie",
    treatmentHistorySubtitle: "Behandlungsübersicht",
    treatmentHistoryDesc: "Alle Behandlungen im Überblick",
    vaccination: "Impfpass",
    vaccinationSubtitle: "Impfungen & Pässe",
    vaccinationDesc: "Impfungen und Gesundheitspässe",
    medication: "Medikation",
    medicationSubtitle: "Medikamentenplan",
    medicationDesc: "Ihre aktuellen Medikamente",
    appointments: "Termine",
    appointmentsSubtitle: "Arzttermine",
    appointmentsDesc: "Alle anstehenden Termine",
    allergies: "Allergien",
    allergiesSubtitle: "Unverträglichkeiten",
    allergiesDesc: "Ihre Allergien und Unverträglichkeiten",
    prevention: "Vorsorge",
    preventionSubtitle: "Prävention",
    preventionDesc: "Vorsorgeuntersuchungen",
    view: "Ansehen",
    dailyPlan: "Tagesplan",
  },
  en: {
    welcome: "Welcome",
    welcomeMessage: "Your personal health record",
    mainMenu: "Main Menu",
    allAreas: "All Areas",
    open: "Open",
    scanDocument: "Scan Document",
    readAloud: "Read Aloud",
    setupLater: "Set up later",
    setupNow: "Set up now",
    welcomeOnboarding: "Welcome to Gesundheit Plus!",
    onboardingMessage: "Let's set up your personal health record together. This only takes a few minutes and can also be done via voice.",
    anamnesis: "Medical History",
    anamnesisSubtitle: "Health History",
    anamnesisDesc: "Your medical background",
    healthcare: "Healthcare Professionals",
    healthcareSubtitle: "Doctors & Therapists",
    healthcareDesc: "All your doctors and therapists",
    treatmentHistory: "Treatment History",
    treatmentHistorySubtitle: "Treatment Overview",
    treatmentHistoryDesc: "All treatments at a glance",
    vaccination: "Vaccination Record",
    vaccinationSubtitle: "Vaccinations & Passes",
    vaccinationDesc: "Vaccinations and health passes",
    medication: "Medication",
    medicationSubtitle: "Medication Plan",
    medicationDesc: "Your current medications",
    appointments: "Appointments",
    appointmentsSubtitle: "Medical Appointments",
    appointmentsDesc: "All upcoming appointments",
    allergies: "Allergies",
    allergiesSubtitle: "Intolerances",
    allergiesDesc: "Your allergies and intolerances",
    prevention: "Prevention",
    preventionSubtitle: "Preventive Care",
    preventionDesc: "Preventive examinations",
    view: "View",
    dailyPlan: "Daily Plan",
  },
  tr: {
    welcome: "Hoş geldiniz",
    welcomeMessage: "Kişisel sağlık dosyanız",
    mainMenu: "Ana Menü",
    allAreas: "Tüm Alanlar",
    open: "Aç",
    scanDocument: "Belge Tara",
    readAloud: "Sesli Oku",
    setupLater: "Sonra ayarla",
    setupNow: "Şimdi ayarla",
    welcomeOnboarding: "Gesundheit Plus'a hoş geldiniz!",
    onboardingMessage: "Kişisel sağlık dosyanızı birlikte oluşturalım. Bu sadece birkaç dakika sürer ve sesli olarak da yapılabilir.",
    anamnesis: "Anamnez",
    anamnesisSubtitle: "Hastalık Geçmişi",
    anamnesisDesc: "Tıbbi geçmişiniz",
    healthcare: "Sağlık Personeli",
    healthcareSubtitle: "Doktorlar ve Terapistler",
    healthcareDesc: "Tüm doktorlarınız ve terapistleriniz",
    treatmentHistory: "Tedavi Geçmişi",
    treatmentHistorySubtitle: "Tedavi Özeti",
    treatmentHistoryDesc: "Tüm tedavilere genel bakış",
    vaccination: "Aşı Kartı",
    vaccinationSubtitle: "Aşılar ve Pasaportlar",
    vaccinationDesc: "Aşılar ve sağlık pasaportları",
    medication: "İlaç",
    medicationSubtitle: "İlaç Planı",
    medicationDesc: "Mevcut ilaçlarınız",
    appointments: "Randevular",
    appointmentsSubtitle: "Doktor Randevuları",
    appointmentsDesc: "Yaklaşan tüm randevular",
    allergies: "Alerjiler",
    allergiesSubtitle: "İntoleranslar",
    allergiesDesc: "Alerjileriniz ve intoleranslarınız",
    prevention: "Önleme",
    preventionSubtitle: "Koruyucu Bakım",
    preventionDesc: "Önleyici muayeneler",
    view: "Görüntüle",
    dailyPlan: "Günlük Plan",
  },
  ar: {
    welcome: "مرحباً",
    welcomeMessage: "سجلك الصحي الشخصي",
    mainMenu: "القائمة الرئيسية",
    allAreas: "جميع المجالات",
    open: "فتح",
    scanDocument: "مسح المستند",
    readAloud: "قراءة بصوت عالٍ",
    setupLater: "الإعداد لاحقاً",
    setupNow: "الإعداد الآن",
    welcomeOnboarding: "مرحباً بك في Gesundheit Plus!",
    onboardingMessage: "دعنا نقوم بإعداد سجلك الصحي الشخصي معاً. يستغرق هذا بضع دقائق فقط ويمكن القيام به أيضاً عبر الصوت.",
    anamnesis: "التاريخ المرضي",
    anamnesisSubtitle: "التاريخ الصحي",
    anamnesisDesc: "خلفيتك الطبية",
    healthcare: "المهنيون الصحيون",
    healthcareSubtitle: "الأطباء والمعالجون",
    healthcareDesc: "جميع أطبائك ومعالجيك",
    treatmentHistory: "تاريخ العلاج",
    treatmentHistorySubtitle: "نظرة عامة على العلاج",
    treatmentHistoryDesc: "جميع العلاجات في لمحة",
    vaccination: "سجل التطعيم",
    vaccinationSubtitle: "التطعيمات والجوازات",
    vaccinationDesc: "التطعيمات وجوازات الصحة",
    medication: "الأدوية",
    medicationSubtitle: "خطة الدواء",
    medicationDesc: "أدويتك الحالية",
    appointments: "المواعيد",
    appointmentsSubtitle: "المواعيد الطبية",
    appointmentsDesc: "جميع المواعيد القادمة",
    allergies: "الحساسية",
    allergiesSubtitle: "عدم التحمل",
    allergiesDesc: "حساسيتك وعدم تحملك",
    prevention: "الوقاية",
    preventionSubtitle: "الرعاية الوقائية",
    preventionDesc: "الفحوصات الوقائية",
    view: "عرض",
    dailyPlan: "الخطة اليومية",
  },
  uk: {
    welcome: "Ласкаво просимо",
    welcomeMessage: "Ваша особиста медична картка",
    mainMenu: "Головне меню",
    allAreas: "Всі розділи",
    open: "Відкрити",
    scanDocument: "Сканувати документ",
    readAloud: "Прочитати вголос",
    setupLater: "Налаштувати пізніше",
    setupNow: "Налаштувати зараз",
    welcomeOnboarding: "Ласкаво просимо до Gesundheit Plus!",
    onboardingMessage: "Давайте разом налаштуємо вашу особисту медичну картку. Це займе лише кілька хвилин і можна зробити голосом.",
    anamnesis: "Анамнез",
    anamnesisSubtitle: "Історія хвороби",
    anamnesisDesc: "Ваша медична історія",
    healthcare: "Медичні працівники",
    healthcareSubtitle: "Лікарі та терапевти",
    healthcareDesc: "Усі ваші лікарі та терапевти",
    treatmentHistory: "Історія лікування",
    treatmentHistorySubtitle: "Огляд лікування",
    treatmentHistoryDesc: "Усі процедури з одного погляду",
    vaccination: "Сертифікат вакцинації",
    vaccinationSubtitle: "Щеплення та паспорти",
    vaccinationDesc: "Щеплення та медичні паспорти",
    medication: "Ліки",
    medicationSubtitle: "План ліків",
    medicationDesc: "Ваші поточні ліки",
    appointments: "Прийоми",
    appointmentsSubtitle: "Медичні прийоми",
    appointmentsDesc: "Усі майбутні прийоми",
    allergies: "Алергії",
    allergiesSubtitle: "Непереносимість",
    allergiesDesc: "Ваші алергії та непереносимість",
    prevention: "Профілактика",
    preventionSubtitle: "Профілактичний догляд",
    preventionDesc: "Профілактичні обстеження",
    view: "Переглянути",
    dailyPlan: "Щоденний план",
  }
};

const LanguageContext = createContext();

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};

export const LanguageProvider = ({ children }) => {
  const [language, setLanguage] = useState('de');
  const [isRTL, setIsRTL] = useState(false);

  useEffect(() => {
    loadLanguagePreference();
  }, []);

  useEffect(() => {
    // Update RTL for Arabic
    setIsRTL(language === 'ar');
    
    // Update document direction
    document.documentElement.dir = language === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = language;
  }, [language]);

  const loadLanguagePreference = async () => {
    try {
      const user = await base44.auth.me();
      if (user.preferred_language) {
        setLanguage(user.preferred_language);
      } else {
        // Detect browser language
        const browserLang = navigator.language.split('-')[0];
        const supportedLangs = ['de', 'en', 'tr', 'ar', 'uk'];
        if (supportedLangs.includes(browserLang)) {
          setLanguage(browserLang);
        }
      }
    } catch (error) {
      console.log("Could not load language preference");
    }
  };

  const changeLanguage = async (newLanguage) => {
    setLanguage(newLanguage);
    
    // Save preference to user profile
    try {
      await base44.auth.updateMe({ preferred_language: newLanguage });
    } catch (error) {
      console.error("Could not save language preference:", error);
    }
  };

  const getTranslation = (key) => {
    return translations[language]?.[key] || translations['de'][key] || key;
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage: changeLanguage, isRTL, getTranslation }}>
      {children}
    </LanguageContext.Provider>
  );
};