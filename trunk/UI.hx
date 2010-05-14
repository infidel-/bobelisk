// javascript ui class

import js.Lib;

class UI
{
  var game: Game;

  var alertWindow: Dynamic; // alert window element
  var alertText: Dynamic; // alert text element
  public var cursorX: Int; // cursor x,y in map coordinates
  public var cursorY: Int;
  public var prevX: Int; // previous mouse coordinates
  public var prevY: Int;

  public var justClicked: Bool; // hack: skip first mouse move after click
  public var msgLocked: Bool; // is msg panel locked until mouse click?

  public function new(g: Game)
    {
      game = g;

      e("version").innerHTML = Game.version;
      e("map").onclick = onMapClick;
      e("map").onmousemove = onMapMove;
      e("restart").onclick = onRestart;
      msgLocked = false;

      // check if canvas is available
      var map = e("map");
      if (!(untyped map).getContext)
        Lib.window.alert("No canvas available. Please use Mozilla Firefox 3.5+ or Google Chrome.");
        
      // alert window
      alertWindow = Lib.document.createElement("alertWindow");
      alertWindow.style.visibility = 'hidden';
      alertWindow.style.position = 'absolute';
      alertWindow.style.zIndex = 20;
      alertWindow.style.width = 600;
      alertWindow.style.height = 450;
      alertWindow.style.left = 200; 
      alertWindow.style.top = 50;
      alertWindow.style.background = '#222';
	  alertWindow.style.border = '4px double #ffffff';
      Lib.document.body.appendChild(alertWindow);

      // alert text
      alertText = Lib.document.createElement("alertText");
      alertText.style.overflow = 'auto';
      alertText.style.position = 'absolute';
      alertText.style.left = 10;
      alertText.style.top = 10;
      alertText.style.width = 580;
      alertText.style.height = 400;
      alertText.style.background = '#111';
	  alertText.style.border = '1px solid #777';
      alertWindow.appendChild(alertText);

      // alert close button
      var alertClose = createCloseButton(alertWindow, 260, 415, 'alertClose');
	  alertClose.onclick = onAlertCloseClick;
    }


// create close button
  function createCloseButton(container: Dynamic, x: Int, y: Int, name: String)
    {
      var b: Dynamic = Lib.document.createElement(name);
      b.innerHTML = '<b>Close</b>';
      b.style.fontSize = 20;
      b.style.position = 'absolute';
      b.style.width = 80;
      b.style.height = 25;
      b.style.left = x;
      b.style.top = y;
      b.style.background = '#111';
	  b.style.border = '1px outset #777';
	  b.style.cursor = 'pointer';
      b.style.textAlign = 'center';
      container.appendChild(b);
      return b;
    }


// hide alert
  function onAlertCloseClick(event)
    {
      alertWindow.style.visibility = 'hidden';
    }


// on clicking restart button
  public function onRestart(event)
    {
      msgLocked = false;
      msg("", false);
      game.restart();
    }


// on map mouse click
  public function onMapClick(event)
    {
      if (game.isFinished)
        return;
  
      // clean msg lock
      if (msgLocked)
        {
          msgLocked = false;
          msg("", false);
        }

      var map = e("map");
      var x = event.clientX - map.offsetLeft;
      var y = event.clientY - map.offsetTop;
      var cellX = Std.int((x - 5) / cellSize); 
      var cellY = Std.int((y - 7) / cellSize);
//      trace(x + "," + y + " -> " + cellX + "," + cellY);

      var cell = game.map.get(cellX, cellY);
      if (cell != null && cell.hasAdjacentWalkable())
        {
          cell.activate();
        }

      justClicked = true;
      paintStatus();
    }


// on map mouse move
  public function onMapMove(event)
    {
      if (justClicked)
        {
          justClicked = false;
          return;
        }
      if (game.isFinished)
        return;

      var map = e("map");
      var x = event.clientX - map.offsetLeft;
      var y = event.clientY - map.offsetTop;

      cursorX = Std.int((x - 5) / cellSize); 
      cursorY = Std.int((y - 7) / cellSize);

      // paint changed rectangle
      game.map.paint(getRect(cursorX, cursorY, repaintRadius));

      // check, if mouse moved more then the rect, repaint all
      var dx = prevX - x;
      var dy = prevY - y;
      if (dx * dx + dy * dy > 10000)
        game.map.paint();

      var cell = game.map.get(cursorX, cursorY);
      if (cell != null && cell.isVisible)
        msg(cell.getNote(), false);
      else msg("", false);

      prevX = x;
      prevY = y;
    }


// get a rect around a cell
  public static function getRect(x: Int, y: Int, radius: Int)
    {
      var rect = { 
        x: 3 + (x - radius) * cellSize,
        y: 2 + (y - radius) * cellSize,
        w: cellSize * radius * 2, h: cellSize * radius * 2 };
      if (radius == 0)
        {
          rect.w = cellSize;
          rect.h = cellSize;
        }
      return rect;
    }


// show a message
  public function msg(s: String, ?isLocked: Bool)
    {
      if (isLocked == null)
        isLocked = true;
//      trace(isLocked + " " + msgLocked);
      if (msgLocked && !isLocked)
        return;
      if (isLocked)
        msgLocked = true;
      e("msg").innerHTML = s;
    }


// repaint status panel (fsta)
  public function paintStatus()
    {
      var s = "<table width=100%><tr><td halign=left>Obelisks found: " +
        game.map.obelisksFound() + " / " + game.map.obelisks.length +
        "<td halign=left>Obelisks shattered: " +
        game.map.obelisksShattered() + " / " + game.map.obelisks.length +
        "<td halign=right><p style='text-align:right; margin-right:5'>" +
        "Turns: " + game.turns + "</table>";
      e("status").innerHTML = s;
    }


// get element shortcut
  public static inline function e(s)
    {
	  return Lib.document.getElementById(s);
	}


// finish the game (ui)
  public function finish(isVictory: Bool)
    {
      var el = untyped UI.e("map");
      var map = el.getContext("2d");
      map.fillStyle = "rgba(0, 0, 0, 0.5)";
      map.fillRect(0, 0, el.width, el.height);

      map.fillStyle = "white";
      var text = "";
      if (isVictory)
        text = "You have found all obelisks in " + game.turns + " turns!";
      else text = "You have never returned from the swamp...";
      var metrics = map.measureText(text);
      map.fillText(text, (el.width - metrics.width) / 2,
        (el.height - cellSize) / 2);
    }


// track stuff through google analytics
  public inline function track(action: String, ?label: String, ?value: Int)
    {
      action += " " + Game.version;
      if (label == null)
        label = '';
      if (value == null)
        value = 0;
      untyped pageTracker._trackEvent('Black Obelisk', action, label, value);
    }


// message with confirmation
  public function alert(s)
    {
      alertText.innerHTML = '<center>' + s + '</center>';
      alertWindow.style.visibility = 'visible';
    }


// get a stored variable (cookie)
  public inline function getVar(name: String)
    {
      return untyped getCookie(name);
    }


// get a stored variable (cookie)
  public inline function setVar(name: String, val: String)
    {
      return untyped setCookie(name, val,
        untyped __js__("new Date(2015, 0, 0, 0, 0, 0, 0)"));
    }


  public static var cellSize: Int = 40;
  public static var mapWidth: Int = 25;
  public static var mapHeight: Int = 16;
  public static var repaintRadius: Int = 3;
}
