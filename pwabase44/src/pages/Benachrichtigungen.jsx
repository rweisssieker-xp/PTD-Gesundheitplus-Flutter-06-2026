import React, { useState } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Bell, Trash2, Check, Calendar, AlertCircle, Info, Clock, X, Pill, Syringe } from "lucide-react";
import { toast } from "sonner";
import { format, formatDistanceToNow } from "date-fns";
import { de } from "date-fns/locale";
import { useNavigate } from "react-router-dom";
import { createPageUrl } from "@/utils";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";

const notificationIcons = {
  appointment_confirmation: Calendar,
  appointment_reminder: Clock,
  appointment_change: AlertCircle,
  appointment_cancellation: X,
  medication_refill: Pill,
  medication_shortage: AlertCircle,
  vaccination_reminder: Syringe,
  info: Info,
  warning: AlertCircle
};

const notificationColors = {
  appointment_confirmation: "from-green-500 to-green-600",
  appointment_reminder: "from-blue-500 to-blue-600",
  appointment_change: "from-orange-500 to-orange-600",
  appointment_cancellation: "from-red-500 to-red-600",
  medication_refill: "from-orange-500 to-orange-600",
  medication_shortage: "from-red-500 to-red-600",
  vaccination_reminder: "from-purple-500 to-purple-600",
  info: "from-indigo-500 to-indigo-600",
  warning: "from-yellow-500 to-yellow-600"
};

export default function BenachrichtigungenPage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [activeTab, setActiveTab] = useState("all");

  const { data: notifications, isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: () => entities.Notification.list('-created_date'),
    initialData: [],
  });

  const markAsReadMutation = useMutation({
    mutationFn: (id) => entities.Notification.update(id, { read: true }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
  });

  const markAllAsReadMutation = useMutation({
    mutationFn: async () => {
      const unreadNotifications = notifications.filter(n => !n.read);
      await Promise.all(
        unreadNotifications.map(n => entities.Notification.update(n.id, { read: true }))
      );
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast.success("Alle Benachrichtigungen als gelesen markiert");
    },
  });

  const deleteNotificationMutation = useMutation({
    mutationFn: (id) => entities.Notification.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast.success("Benachrichtigung gelöscht");
    },
  });

  const deleteAllMutation = useMutation({
    mutationFn: async () => {
      await Promise.all(notifications.map(n => entities.Notification.delete(n.id)));
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast.success("Alle Benachrichtigungen gelöscht");
    },
  });

  const handleNotificationClick = (notification) => {
    if (!notification.read) {
      markAsReadMutation.mutate(notification.id);
    }
    if (notification.action_url) {
      navigate(notification.action_url);
    }
  };

  const unreadNotifications = notifications.filter(n => !n.read);
  const readNotifications = notifications.filter(n => n.read);
  const highPriorityNotifications = notifications.filter(n => n.priority === 'high');

  const renderNotificationsList = (notificationsList) => {
    if (notificationsList.length === 0) {
      return (
        <Card className="border-2 border-dashed">
          <CardContent className="py-12 text-center">
            <Bell className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500">Keine Benachrichtigungen</p>
          </CardContent>
        </Card>
      );
    }

    return (
      <div className="space-y-3">
        {notificationsList.map((notification) => {
          const Icon = notificationIcons[notification.type] || Info;
          const colorClass = notificationColors[notification.type] || "from-gray-500 to-gray-600";
          
          return (
            <Card 
              key={notification.id} 
              className={`border-2 hover:shadow-lg transition-shadow cursor-pointer ${
                !notification.read ? 'border-blue-300 bg-blue-50' : ''
              } ${notification.priority === 'high' ? 'border-l-4 border-l-red-500' : ''}`}
              onClick={() => handleNotificationClick(notification)}
            >
              <CardContent className="p-4">
                <div className="flex gap-3">
                  <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${colorClass} flex items-center justify-center flex-shrink-0`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2 mb-1">
                      <h3 className="text-sm font-bold text-gray-900">{notification.title}</h3>
                      {!notification.read && (
                        <div className="w-2 h-2 bg-blue-600 rounded-full flex-shrink-0 mt-1" />
                      )}
                    </div>
                    <p className="text-sm text-gray-700 mb-2">{notification.message}</p>
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge variant={notification.priority === 'high' ? 'destructive' : 'outline'}>
                        {notification.priority === 'high' ? '🚨 Wichtig' : 
                         notification.priority === 'medium' ? 'Normal' : 'Info'}
                      </Badge>
                      <span className="text-xs text-gray-500">
                        {formatDistanceToNow(new Date(notification.created_date), { 
                          addSuffix: true, 
                          locale: de 
                        })}
                      </span>
                    </div>
                  </div>
                  <div className="flex flex-col gap-2">
                    {!notification.read && (
                      <Button
                        onClick={(e) => {
                          e.stopPropagation();
                          markAsReadMutation.mutate(notification.id);
                        }}
                        size="icon"
                        variant="ghost"
                        className="h-8 w-8"
                      >
                        <Check className="h-4 w-4 text-green-600" />
                      </Button>
                    )}
                    <Button
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteNotificationMutation.mutate(notification.id);
                      }}
                      size="icon"
                      variant="ghost"
                      className="h-8 w-8"
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    );
  };

  return (
    <div className="p-6 space-y-4 pb-24">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Benachrichtigungen</h1>
          <p className="text-gray-600">Alle Ihre Mitteilungen</p>
        </div>
      </div>

      {/* Summary Card */}
      <Card className="bg-gradient-to-r from-red-500 to-red-600 text-white border-0">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-red-100 text-sm">Ungelesene Benachrichtigungen</p>
              <p className="text-4xl font-bold">{unreadNotifications.length}</p>
              {highPriorityNotifications.filter(n => !n.read).length > 0 && (
                <p className="text-sm text-red-100 mt-1">
                  🚨 {highPriorityNotifications.filter(n => !n.read).length} dringende
                </p>
              )}
            </div>
            <Bell className="h-16 w-16 text-red-200" />
          </div>
        </CardContent>
      </Card>

      {/* Action Buttons */}
      {notifications.length > 0 && (
        <div className="flex gap-2">
          <Button
            onClick={() => markAllAsReadMutation.mutate()}
            disabled={unreadNotifications.length === 0}
            variant="outline"
            className="flex-1"
          >
            <Check className="h-4 w-4 mr-2" />
            Alle als gelesen
          </Button>
          <Button
            onClick={() => {
              if (confirm("Möchten Sie wirklich alle Benachrichtigungen löschen?")) {
                deleteAllMutation.mutate();
              }
            }}
            variant="outline"
            className="flex-1"
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Alle löschen
          </Button>
        </div>
      )}

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="w-full">
          <TabsTrigger value="all" className="flex-1">
            Alle ({notifications.length})
          </TabsTrigger>
          <TabsTrigger value="unread" className="flex-1">
            Ungelesen ({unreadNotifications.length})
          </TabsTrigger>
          <TabsTrigger value="high" className="flex-1">
            🚨 Wichtig ({highPriorityNotifications.length})
          </TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="space-y-3 mt-4">
          {isLoading ? (
            <p className="text-center text-gray-500 py-8">Lade Benachrichtigungen...</p>
          ) : (
            renderNotificationsList(notifications)
          )}
        </TabsContent>

        <TabsContent value="unread" className="space-y-3 mt-4">
          {renderNotificationsList(unreadNotifications)}
        </TabsContent>

        <TabsContent value="high" className="space-y-3 mt-4">
          {renderNotificationsList(highPriorityNotifications)}
        </TabsContent>
      </Tabs>
    </div>
  );
}