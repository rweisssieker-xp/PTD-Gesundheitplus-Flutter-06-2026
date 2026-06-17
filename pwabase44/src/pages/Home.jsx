import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { createPageUrl } from "@/utils";
import { 
  FileText, 
  Stethoscope, 
  Syringe, 
  Pill, 
  Calendar, 
  AlertCircle,
  ClipboardCheck,
  ChevronLeft,
  ChevronRight,
  Volume2,
  ScanLine,
  History,
  Brain,
  MessageSquare,
  ListChecks,
  Activity,
  Scale,
  AlertTriangle,
  Users,
  ShieldAlert,
  Download
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { base44 } from "@/api/base44Client";
import NotificationService from "@/components/NotificationService";
import EmergencyButton from "@/components/EmergencyButton";
import HealthAIChat from "@/components/HealthAIChat";
import { useLanguage } from "@/components/LanguageProvider";

export default function HomePage() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [touchStart, setTouchStart] = useState(0);
  const [touchEnd, setTouchEnd] = useState(0);
  const [user, setUser] = useState(null);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showAIChat, setShowAIChat] = useState(false);
  const [healthAlert, setHealthAlert] = useState(null);
  const { language, getTranslation } = useLanguage();

  const t = (key) => getTranslation(key);

  const menuItems = [
    {
      title: t('anamnesis'),
      subtitle: t('anamnesisSubtitle'),
      icon: FileText,
      page: "Anamnese",
      color: "from-blue-500 to-blue-600",
      description: t('anamnesisDesc')
    },
    {
      title: t('healthcare'),
      subtitle: t('healthcareSubtitle'),
      icon: Stethoscope,
      page: "Heilberufe",
      color: "from-green-500 to-green-600",
      description: t('healthcareDesc')
    },
    {
      title: t('treatmentHistory'),
      subtitle: t('treatmentHistorySubtitle'),
      icon: History,
      page: "Behandlungshistorie",
      color: "from-teal-500 to-teal-600",
      description: t('treatmentHistoryDesc')
    },
    {
      title: t('vaccination'),
      subtitle: t('vaccinationSubtitle'),
      icon: Syringe,
      page: "Impfpass",
      color: "from-purple-500 to-purple-600",
      description: t('vaccinationDesc')
    },
    {
      title: t('medication'),
      subtitle: t('medicationSubtitle'),
      icon: Pill,
      page: "Medikation",
      color: "from-orange-500 to-orange-600",
      description: t('medicationDesc')
    },
    {
      title: t('appointments'),
      subtitle: t('appointmentsSubtitle'),
      icon: Calendar,
      page: "Termine",
      color: "from-red-500 to-red-600",
      description: t('appointmentsDesc')
    },
    {
      title: t('allergies'),
      subtitle: t('allergiesSubtitle'),
      icon: AlertCircle,
      page: "Allergien",
      color: "from-yellow-500 to-yellow-600",
      description: t('allergiesDesc')
    },
    {
      title: t('prevention'),
      subtitle: t('preventionSubtitle'),
      icon: ClipboardCheck,
      page: "Vorsorge",
      color: "from-indigo-500 to-indigo-600",
      description: t('preventionDesc')
    },
    {
      title: "Blutdruck",
      subtitle: "Messwerte",
      icon: Activity,
      page: "Blutdruck",
      color: "from-rose-500 to-rose-600",
      description: "Blutdruck & Puls"
    },
    {
      title: "Gewicht",
      subtitle: "BMI & Verlauf",
      icon: Scale,
      page: "Gewicht",
      color: "from-violet-500 to-violet-600",
      description: "Gewichtskontrolle"
    }
  ];

  useEffect(() => {
    loadUser();
    checkProactiveAlerts();
  }, []);

  const loadUser = async () => {
    try {
      const userData = await base44.auth.me();
      setUser(userData);
      
      if (!userData.date_of_birth) {
        setShowOnboarding(true);
      }
    } catch (error) {
      console.log("User not loaded", error);
    }
  };

  const checkProactiveAlerts = async () => {
    try {
      const medications = await base44.entities.Medication.filter({ active: true });
      const needsRefill = medications.filter(m => {
        if (!m.supply_duration_days || !m.start_date) return false;
        
        const startDate = new Date(m.start_date);
        const daysSinceStart = Math.floor((new Date() - startDate) / (1000 * 60 * 60 * 24));
        const daysRemaining = m.supply_duration_days - daysSinceStart;
        const reminderDays = m.refill_reminder_days || 7;
        
        return daysRemaining <= reminderDays && daysRemaining > 0;
      });

      if (needsRefill.length > 0) {
        setHealthAlert({
          type: 'medication',
          severity: 'medium',
          message: `${needsRefill.length} Medikament(e) bald aufgebraucht`,
          action: 'Rezept anfordern',
          link: '/Medikation'
        });
      }

      const appointments = await base44.entities.Appointment.list();
      const today = new Date().toISOString().split('T')[0];
      const todaysAppointments = appointments.filter(a => 
        a.date === today && a.status !== 'Abgesagt'
      );

      if (todaysAppointments.length > 0 && !needsRefill.length) {
        setHealthAlert({
          type: 'appointment',
          severity: 'low',
          message: `${todaysAppointments.length} Termin(e) heute`,
          action: 'Details ansehen',
          link: '/Termine'
        });
      }

    } catch (error) {
      console.error('Alert check error:', error);
    }
  };

  const currentItem = menuItems[currentIndex];

  const goToNext = () => {
    setCurrentIndex((prev) => (prev + 1) % menuItems.length);
  };

  const goToPrevious = () => {
    setCurrentIndex((prev) => (prev - 1 + menuItems.length) % menuItems.length);
  };

  const handleTouchStart = (e) => {
    setTouchStart(e.targetTouches[0].clientX);
  };

  const handleTouchMove = (e) => {
    setTouchEnd(e.targetTouches[0].clientX);
  };

  const handleTouchEnd = () => {
    if (touchStart - touchEnd > 75) {
      goToNext();
    }
    if (touchStart - touchEnd < -75) {
      goToPrevious();
    }
  };

  const speakText = (text) => {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(text);
      const langMap = {
        de: 'de-DE',
        en: 'en-US',
        tr: 'tr-TR',
        ar: 'ar-SA',
        uk: 'uk-UA'
      };
      utterance.lang = langMap[language] || 'de-DE';
      speechSynthesis.speak(utterance);
    }
  };

  const Icon = currentItem.icon;

  if (showOnboarding) {
    return (
      <div className="min-h-screen">
        <div className="p-6">
          <Button
            onClick={() => setShowOnboarding(false)}
            variant="outline"
            className="mb-4"
          >
            {t('setupLater')}
          </Button>
        </div>
        <div className="p-6">
          <Card className="border-2 bg-blue-50 border-blue-200 mb-6">
            <CardContent className="pt-6">
              <h2 className="text-xl font-bold text-blue-900 mb-2">
                {t('welcomeOnboarding')}
              </h2>
              <p className="text-blue-700 mb-4">
                {t('onboardingMessage')}
              </p>
              <Link to={createPageUrl("Onboarding")}>
                <Button size="lg" className="w-full bg-blue-600 hover:bg-blue-700">
                  <Volume2 className="h-5 w-5 mr-2" />
                  {t('setupNow')}
                </Button>
              </Link>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-red-50 to-white pb-4">
      <NotificationService />

      {user && (
        <div className="bg-white shadow-sm border-b-2 border-red-100 px-6 py-4">
          <h2 className="text-lg font-semibold text-gray-900">
            {t('welcome')}, {user.full_name || 'Patient'}!
          </h2>
          <p className="text-sm text-gray-600">{t('welcomeMessage')}</p>
        </div>
      )}

      <div className="px-6 py-4 space-y-3">
        {healthAlert && (
          <Card className={`border-2 ${
            healthAlert.severity === 'high' ? 'border-red-200 bg-red-50' :
            healthAlert.severity === 'medium' ? 'border-yellow-200 bg-yellow-50' :
            'border-blue-200 bg-blue-50'
          }`}>
            <CardContent className="pt-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <AlertTriangle className={`h-5 w-5 ${
                    healthAlert.severity === 'high' ? 'text-red-600' :
                    healthAlert.severity === 'medium' ? 'text-yellow-600' :
                    'text-blue-600'
                  }`} />
                  <div>
                    <p className="font-semibold text-gray-900 text-sm">{healthAlert.message}</p>
                    <p className="text-xs text-gray-600">{healthAlert.action}</p>
                  </div>
                </div>
                <a href={healthAlert.link}>
                  <Button size="sm" variant="outline">
                    {t('view')}
                  </Button>
                </a>
              </div>
            </CardContent>
          </Card>
        )}

        <EmergencyButton />

        <div className="grid grid-cols-4 gap-3">
          <Link to={createPageUrl("KI-Gesundheitscoach")}>
            <Button className="w-full h-20 bg-gradient-to-r from-purple-500 to-pink-600 hover:from-purple-600 hover:to-pink-700 text-white shadow-lg">
              <div className="flex flex-col items-center gap-2">
                <Brain className="h-6 w-6" />
                <span className="text-xs font-semibold">KI-Coach</span>
              </div>
            </Button>
          </Link>
          
          <Link to={createPageUrl("Dokumenten-Scan")}>
            <Button className="w-full h-20 bg-gradient-to-r from-indigo-500 to-indigo-600 hover:from-indigo-600 hover:to-indigo-700 text-white shadow-lg">
              <div className="flex flex-col items-center gap-2">
                <ScanLine className="h-6 w-6" />
                <span className="text-xs font-semibold">{t('scanDocument')}</span>
              </div>
            </Button>
          </Link>
          
          <Link to={createPageUrl("Medikamenten-Tagesplan")}>
            <Button className="w-full h-20 bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white shadow-lg">
              <div className="flex flex-col items-center gap-2">
                <ListChecks className="h-6 w-6" />
                <span className="text-xs font-semibold">{t('dailyPlan')}</span>
              </div>
            </Button>
          </Link>
          
          <Button 
            onClick={() => setShowAIChat(true)}
            className="w-full h-20 bg-gradient-to-r from-pink-500 to-pink-600 hover:from-pink-600 hover:to-pink-700 text-white shadow-lg"
          >
            <div className="flex flex-col items-center gap-2">
              <MessageSquare className="h-6 w-6" />
              <span className="text-xs font-semibold">KI-Chat</span>
            </div>
          </Button>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Link to={createPageUrl("Familien-Kreis")}>
            <Button className="w-full h-20 bg-gradient-to-r from-teal-500 to-teal-600 hover:from-teal-600 hover:to-teal-700 text-white shadow-lg">
              <div className="flex flex-col items-center gap-2">
                <Users className="h-6 w-6" />
                <span className="text-xs font-semibold">Familienkreis</span>
              </div>
            </Button>
          </Link>
          <Link to={createPageUrl("Wechselwirkungen-Checker")}>
            <Button className="w-full h-20 bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white shadow-lg">
              <div className="flex flex-col items-center gap-2">
                <ShieldAlert className="h-6 w-6" />
                <span className="text-xs font-semibold">Wechselwirkungen</span>
              </div>
            </Button>
          </Link>
        </div>

        <div className="grid grid-cols-1 gap-3">
          <Link to={createPageUrl("Daten-Export")}>
            <Button className="w-full h-14 bg-gradient-to-r from-gray-700 to-gray-900 hover:from-gray-800 hover:to-black text-white shadow-lg">
              <Download className="h-5 w-5 mr-2" />
              <span className="text-sm font-semibold">Gesundheitsakte exportieren</span>
            </Button>
          </Link>
        </div>
      </div>

      <div className="px-6 py-2">
        <div 
          className="relative"
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
        >
          <Link to={createPageUrl(currentItem.page)}>
            <Card className="relative overflow-hidden shadow-2xl border-2 border-gray-200 active:scale-95 transition-transform">
              <div className={`absolute inset-0 bg-gradient-to-br ${currentItem.color} opacity-10`}></div>
              <div className="relative p-8 min-h-[400px] flex flex-col items-center justify-center text-center">
                <div className={`w-24 h-24 mb-6 rounded-full bg-gradient-to-br ${currentItem.color} flex items-center justify-center shadow-xl`}>
                  <Icon className="h-12 w-12 text-white" />
                </div>
                <h2 className="text-3xl font-bold text-gray-900 mb-2">
                  {currentItem.title}
                </h2>
                <p className="text-lg text-gray-600 mb-4">
                  {currentItem.subtitle}
                </p>
                <p className="text-sm text-gray-500">
                  {currentItem.description}
                </p>
                <div className="mt-8">
                  <Button 
                    size="lg" 
                    className={`bg-gradient-to-r ${currentItem.color} hover:opacity-90 text-white shadow-lg text-lg px-8 py-6`}
                  >
                    {t('open')}
                  </Button>
                </div>
              </div>
            </Card>
          </Link>

          <div className="absolute top-1/2 -translate-y-1/2 left-0 right-0 flex justify-between px-2 pointer-events-none">
            <Button
              size="icon"
              onClick={(e) => {
                e.preventDefault();
                goToPrevious();
              }}
              className="h-16 w-16 rounded-full bg-white shadow-2xl hover:bg-gray-50 pointer-events-auto border-2 border-gray-200"
            >
              <ChevronLeft className="h-8 w-8 text-gray-700" />
            </Button>
            <Button
              size="icon"
              onClick={(e) => {
                e.preventDefault();
                goToNext();
              }}
              className="h-16 w-16 rounded-full bg-white shadow-2xl hover:bg-gray-50 pointer-events-auto border-2 border-gray-200"
            >
              <ChevronRight className="h-8 w-8 text-gray-700" />
            </Button>
          </div>
        </div>

        <div className="flex justify-center gap-2 mt-6">
          {menuItems.map((_, index) => (
            <button
              key={index}
              onClick={() => setCurrentIndex(index)}
              className={`h-2 rounded-full transition-all ${
                index === currentIndex 
                  ? 'w-8 bg-red-600' 
                  : 'w-2 bg-gray-300'
              }`}
            />
          ))}
        </div>
      </div>

      <div className="px-6 py-4">
        <h3 className="text-sm font-semibold text-gray-500 mb-3 uppercase tracking-wide">
          {t('allAreas')}
        </h3>
        <div className="grid grid-cols-2 gap-3">
          {menuItems.map((item, index) => {
            const ItemIcon = item.icon;
            return (
              <Link key={index} to={createPageUrl(item.page)}>
                <div className="p-4 hover:shadow-lg transition-shadow border-2 rounded-lg active:scale-95 transform transition-transform bg-white">
                  <div className="flex flex-col items-center text-center gap-2">
                    <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${item.color} flex items-center justify-center`}>
                      <ItemIcon className="h-6 w-6 text-white" />
                    </div>
                    <div>
                      <p className="font-semibold text-sm text-gray-900">{item.title}</p>
                      <p className="text-xs text-gray-500">{item.subtitle}</p>
                    </div>
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      </div>

      {showAIChat && <HealthAIChat onClose={() => setShowAIChat(false)} />}
    </div>
  );
}