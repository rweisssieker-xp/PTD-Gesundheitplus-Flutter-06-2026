
import React, { useState } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Bell, X, Check, Calendar, AlertCircle, Info, Clock, Pill, Syringe } from "lucide-react";
import { toast } from "sonner";
import { formatDistanceToNow } from "date-fns";
import { de } from "date-fns/locale";
import { useNavigate } from "react-router-dom";
import { createPageUrl } from "@/utils";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

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

export default function NotificationCenter() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [selectedNotification, setSelectedNotification] = useState(null);

  const { data: notifications, isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: () => base44.entities.Notification.list('-created_date'),
    initialData: [],
  });

  const markAsReadMutation = useMutation({
    mutationFn: (id) => base44.entities.Notification.update(id, { read: true }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
  });

  const markAllAsReadMutation = useMutation({
    mutationFn: async () => {
      const unreadNotifications = notifications.filter(n => !n.read);
      await Promise.all(
        unreadNotifications.map(n => base44.entities.Notification.update(n.id, { read: true }))
      );
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast.success("Alle Benachrichtigungen als gelesen markiert");
    },
  });

  const deleteNotificationMutation = useMutation({
    mutationFn: (id) => base44.entities.Notification.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast.success("Benachrichtigung gelöscht");
    },
  });

  const deleteAllMutation = useMutation({
    mutationFn: async () => {
      await Promise.all(notifications.map(n => base44.entities.Notification.delete(n.id)));
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
    setSelectedNotification(notification);
    setIsDialogOpen(true);
  };

  const handleActionClick = (notification) => {
    if (notification.action_url) {
      navigate(notification.action_url);
      setIsDialogOpen(false);
    }
  };

  const unreadCount = notifications.filter(n => !n.read).length;
  const highPriorityCount = notifications.filter(n => !n.read && n.priority === 'high').length;
  const recentNotifications = notifications.slice(0, 5);

  return (
    <>
      {/* Popover for quick view */}
      <Popover>
        <PopoverTrigger asChild>
          <Button variant="ghost" size="icon" className="relative">
            <Bell className="h-5 w-5" />
            {unreadCount > 0 && (
              <Badge 
                className={`absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 ${
                  highPriorityCount > 0 ? 'bg-red-600 animate-pulse' : 'bg-red-600'
                }`}
              >
                {unreadCount > 9 ? '9+' : unreadCount}
              </Badge>
            )}
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-80 p-0" align="end">
          <div className="p-4 border-b bg-gradient-to-r from-red-500 to-red-600 text-white">
            <div className="flex items-center justify-between">
              <h3 className="font-semibold">Benachrichtigungen</h3>
              {unreadCount > 0 && (
                <Badge className="bg-white text-red-600">
                  {unreadCount} neu
                </Badge>
              )}
            </div>
          </div>
          
          {isLoading ? (
            <div className="p-8 text-center text-gray-500">
              Lade Benachrichtigungen...
            </div>
          ) : notifications.length === 0 ? (
            <div className="p-8 text-center">
              <Bell className="h-12 w-12 text-gray-300 mx-auto mb-3" />
              <p className="text-sm text-gray-500">Keine Benachrichtigungen</p>
            </div>
          ) : (
            <>
              <div className="max-h-96 overflow-y-auto">
                {recentNotifications.map((notification) => {
                  const Icon = notificationIcons[notification.type] || Info;
                  const colorClass = notificationColors[notification.type] || "from-gray-500 to-gray-600";
                  
                  return (
                    <div
                      key={notification.id}
                      onClick={() => handleNotificationClick(notification)}
                      className={`p-4 border-b hover:bg-gray-50 cursor-pointer transition-colors ${
                        !notification.read ? 'bg-blue-50' : ''
                      } ${notification.priority === 'high' ? 'border-l-4 border-l-red-500' : ''}`}
                    >
                      <div className="flex gap-3">
                        <div className={`w-10 h-10 rounded-lg bg-gradient-to-br ${colorClass} flex items-center justify-center flex-shrink-0`}>
                          <Icon className="h-5 w-5 text-white" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <p className={`text-sm font-semibold ${!notification.read ? 'text-gray-900' : 'text-gray-700'}`}>
                              {notification.title}
                            </p>
                            {!notification.read && (
                              <div className="w-2 h-2 bg-blue-600 rounded-full flex-shrink-0 mt-1" />
                            )}
                          </div>
                          <p className="text-xs text-gray-600 line-clamp-2 mt-1">
                            {notification.message}
                          </p>
                          <p className="text-xs text-gray-400 mt-1">
                            {formatDistanceToNow(new Date(notification.created_date), { 
                              addSuffix: true, 
                              locale: de 
                            })}
                          </p>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
              
              <div className="p-3 border-t bg-gray-50 flex gap-2">
                <Button
                  onClick={() => navigate(createPageUrl("Benachrichtigungen"))}
                  variant="outline"
                  size="sm"
                  className="flex-1"
                >
                  Alle anzeigen
                </Button>
                {unreadCount > 0 && (
                  <Button
                    onClick={(e) => {
                      e.stopPropagation();
                      markAllAsReadMutation.mutate();
                    }}
                    variant="outline"
                    size="sm"
                    className="flex-1"
                  >
                    <Check className="h-4 w-4 mr-1" />
                    Alle gelesen
                  </Button>
                )}
              </div>
            </>
          )}
        </PopoverContent>
      </Popover>

      {/* Detailed notification dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent>
          {selectedNotification && (
            <>
              <DialogHeader>
                <DialogTitle>{selectedNotification.title}</DialogTitle>
              </DialogHeader>
              <div className="space-y-4 py-4">
                <div className="flex gap-3">
                  {(() => {
                    const Icon = notificationIcons[selectedNotification.type] || Info;
                    const colorClass = notificationColors[selectedNotification.type] || "from-gray-500 to-gray-600";
                    return (
                      <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${colorClass} flex items-center justify-center flex-shrink-0`}>
                        <Icon className="h-6 w-6 text-white" />
                      </div>
                    );
                  })()}
                  <div className="flex-1">
                    <Badge className={selectedNotification.priority === 'high' ? 'bg-red-600' : 'bg-blue-600'}>
                      {selectedNotification.priority === 'high' ? 'Wichtig' : 
                       selectedNotification.priority === 'medium' ? 'Normal' : 'Info'}
                    </Badge>
                    <p className="text-xs text-gray-500 mt-1">
                      {formatDistanceToNow(new Date(selectedNotification.created_date), { 
                        addSuffix: true, 
                        locale: de 
                      })}
                    </p>
                  </div>
                </div>
                
                <div className="bg-gray-50 rounded-lg p-4">
                  <p className="text-sm text-gray-700">{selectedNotification.message}</p>
                </div>

                <div className="flex gap-2">
                  {selectedNotification.action_url && (
                    <Button
                      onClick={() => handleActionClick(selectedNotification)}
                      className="flex-1"
                    >
                      Details anzeigen
                    </Button>
                  )}
                  <Button
                    onClick={() => {
                      deleteNotificationMutation.mutate(selectedNotification.id);
                      setIsDialogOpen(false);
                    }}
                    variant="outline"
                    className="flex-1"
                  >
                    <X className="h-4 w-4 mr-1" />
                    Löschen
                  </Button>
                </div>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </>
  );
}
