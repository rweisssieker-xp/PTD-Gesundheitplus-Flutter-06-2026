import Allergien from './pages/Allergien';
import Anamnese from './pages/Anamnese';
import Behandlungshistorie from './pages/Behandlungshistorie';
import Benachrichtigungen from './pages/Benachrichtigungen';
import Blutdruck from './pages/Blutdruck';
import Datenschutz from './pages/Datenschutz';
import demenzUnterstTzung from './pages/Demenz-Unterstützung';
import dokumentenScan from './pages/Dokumenten-Scan';
import gescannteDokumente from './pages/Gescannte-Dokumente';
import gesundheitsDashboard from './pages/Gesundheits-Dashboard';
import Gewicht from './pages/Gewicht';
import Heilberufe from './pages/Heilberufe';
import Home from './pages/Home';
import Impfpass from './pages/Impfpass';
import kiGesundheitscoach from './pages/KI-Gesundheitscoach';
import medikamentenTagesplan from './pages/Medikamenten-Tagesplan';
import Medikation from './pages/Medikation';
import medikationsInteraktionen from './pages/Medikations-Interaktionen';
import notfallEinrichtung from './pages/Notfall-Einrichtung';
import Notfallprofil from './pages/Notfallprofil';
import offlineNotfall from './pages/Offline-Notfall';
import Onboarding from './pages/Onboarding';
import telegramSetup from './pages/Telegram-Setup';
import Termine from './pages/Termine';
import twilioSetup from './pages/Twilio-Setup';
import Vorsorge from './pages/Vorsorge';
import __Layout from './Layout.jsx';


export const PAGES = {
    "Allergien": Allergien,
    "Anamnese": Anamnese,
    "Behandlungshistorie": Behandlungshistorie,
    "Benachrichtigungen": Benachrichtigungen,
    "Blutdruck": Blutdruck,
    "Datenschutz": Datenschutz,
    "Demenz-Unterstützung": demenzUnterstTzung,
    "Dokumenten-Scan": dokumentenScan,
    "Gescannte-Dokumente": gescannteDokumente,
    "Gesundheits-Dashboard": gesundheitsDashboard,
    "Gewicht": Gewicht,
    "Heilberufe": Heilberufe,
    "Home": Home,
    "Impfpass": Impfpass,
    "KI-Gesundheitscoach": kiGesundheitscoach,
    "Medikamenten-Tagesplan": medikamentenTagesplan,
    "Medikation": Medikation,
    "Medikations-Interaktionen": medikationsInteraktionen,
    "Notfall-Einrichtung": notfallEinrichtung,
    "Notfallprofil": Notfallprofil,
    "Offline-Notfall": offlineNotfall,
    "Onboarding": Onboarding,
    "Telegram-Setup": telegramSetup,
    "Termine": Termine,
    "Twilio-Setup": twilioSetup,
    "Vorsorge": Vorsorge,
}

export const pagesConfig = {
    mainPage: "Home",
    Pages: PAGES,
    Layout: __Layout,
};