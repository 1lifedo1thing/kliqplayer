#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Quand Hyprland agrandit d'un coup la fenêtre (d'un quart d'écran à tout
// l'écran), Flutter met un moment à dessiner à la nouvelle taille ; en
// attendant, l'ancienne image est répétée en mosaïque (quatre baladeurs quand
// la fenêtre double). On la rend alors transparente jusqu'à ce que l'appli signale
// (« drawn » sur kliqplayer/window) qu'une image à la bonne taille est prête.
static gboolean stale = FALSE;
static int last_width = 0, last_height = 0;
static guint stale_timeout = 0;

static gboolean show_again(gpointer view) {
  stale = FALSE;
  gtk_widget_set_opacity(GTK_WIDGET(view), 1.0);
  if (stale_timeout != 0) g_source_remove(stale_timeout);
  stale_timeout = 0;
  return G_SOURCE_REMOVE;
}

static gboolean stale_timeout_cb(gpointer view) {
  stale_timeout = 0;  // la source se retire d'elle-même
  return show_again(view);
}

static void view_size_cb(GtkWidget* view, GdkRectangle* a, gpointer data) {
  // Les petits pas (redimensionnement à la souris) ne se voient pas : seul un
  // agrandissement franc cache la fenêtre.
  if (last_width > 0 && (a->width > last_width * 1.15 || a->height > last_height * 1.15)) {
    stale = TRUE;
    // Rendue transparente le temps de redessiner (pas d'interception de
    // chaque dessin : elle ralentissait tout le rendu).
    gtk_widget_set_opacity(view, 0.0);
    if (stale_timeout != 0) g_source_remove(stale_timeout);
    // Au cas où l'appli ne répond pas : on réaffiche quand même.
    stale_timeout = g_timeout_add(600, stale_timeout_cb, view);
  }
  last_width = a->width;
  last_height = a->height;
}

static void window_method_cb(FlMethodChannel* channel, FlMethodCall* call, gpointer view) {
  if (g_strcmp0(fl_method_call_get_name(call), "drawn") == 0) {
    if (stale) show_again(view);
    fl_method_call_respond_success(call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
  }
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Fenêtre sans décoration et transparente : seul le baladeur est visible.
  gtk_window_set_title(window, "KliqPlayer");
  gtk_window_set_decorated(window, FALSE);
  GdkScreen* screen = gtk_window_get_screen(window);
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr) {
    gtk_widget_set_visual(GTK_WIDGET(window), visual);
  }
  gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);

  gtk_window_set_default_size(window, 1236, 600);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#00000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_signal_connect(view, "size-allocate", G_CALLBACK(view_size_cb), nullptr);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), "kliqplayer/window", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, window_method_cb, view, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
