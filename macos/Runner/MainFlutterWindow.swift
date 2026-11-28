import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    // L'iPod flotte seul : fenêtre et vue Flutter transparentes dès le départ
    // (avant que Dart n'enlève la barre de titre), sans cadre qui clignote.
    flutterViewController.backgroundColor = .clear
    self.isOpaque = false
    self.backgroundColor = .clear
    // macOS calcule l'ombre une fois sur les pixels opaques d'une image
    // ancienne : elle laissait un contour sombre décalé autour de l'iPod.
    self.hasShadow = false
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // macOS ramène d'office une fenêtre dans l'écran (sous la barre des menus) :
  // on veut pouvoir laisser l'iPod à moitié sorti du bord.
  override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
    return frameRect
  }
}
