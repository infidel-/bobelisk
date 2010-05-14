// map cell class

class Cell
{
  public var map: Map;
  var ui: UI;
  var game: Game;

  public var x: Int;
  public var y: Int;
  public var type: String;
  public var isVisible: Bool;
  public var hasZombie: Bool;
  public var zombieAlerted: Bool;

  public function new(g: Game)
    {
      game = g;
      map = game.map;
      ui = game.ui;
      hasZombie = false;
      zombieAlerted = false;
    }


  public static var colors: Dynamic =
    {
      grass: "green",
      building: "gray",
      swamp: "#339999",
      water: "blue",
      tree: "darkgreen",
      obelisk: "gray",
      fakeObelisk: "#222222",
      shatteredObelisk: "gray",
      zombie: "gray",
    };

  public static var symbols: Dynamic =
    {
      grass: ".",
      building: "#",
      swamp: ".",
      water: "~",
      tree: "*",
      obelisk: "+",
      fakeObelisk: "+",
      shatteredObelisk: "_",
      zombie: "z"
    };

  static var walkable: Dynamic =
    {
      grass: true,
      building: false,
      swamp: true,
      water: false,
      tree: false,
      obelisk: true,
      shatteredObelisk: true,
      zombie: true
    };


  public static var names: Dynamic =
    {
      shatteredObelisk: "shattered obelisk"
    }


  static var dx: Array<Int> = [ 1, -1, 0, 0, 1, -1, 1, -1 ];
  static var dy: Array<Int> = [ 0, 0, 1, -1, 1, -1, -1, 1 ];


// paint cell
  public function paint(screen: Dynamic, isSelected: Bool, rect: Dynamic)
    {
      var x1 = 3 + x * UI.cellSize;
      var x2 = 3 + x * UI.cellSize + UI.cellSize;
      var y1 = 2 + y * UI.cellSize;
      var y2 = 2 + y * UI.cellSize + UI.cellSize;
      if (!(x1 >= rect.x && x1 < rect.x + rect.w &&
            y1 >= rect.y && y1 < rect.y + rect.h) &&
          !(x2 > rect.x && x2 <= rect.x + rect.w &&
            y2 > rect.y && y2 <= rect.y + rect.h))
        return;

      // paint selected
      if (isSelected)
        paintSelected(screen);

      screen.fillStyle = Reflect.field(colors, type);
      var sym = Reflect.field(symbols, type);
      var xx = 5 + x * UI.cellSize;
      var yy = -1 + y * UI.cellSize;
      if (hasZombie)
        {
          screen.fillStyle = colors.zombie;
          sym = symbols.zombie;
        }
      if (sym == "_")
        {
          xx += 4;
          yy -= 6;
        }
      if (isVisible)
        screen.fillText(sym, xx, yy);
    }


// helper, paint selected cell
  function paintSelected(screen)
    {
      if (//!hasAdjacentVisible() || 
          !hasAdjacentWalkable() || game.isFinished)
        return;

      // find distance to closest zombie in 7x7 square
      var dist = 10;
      for (dy in -3...3)
        for (dx in -3...3)
          {
            var c = map.get(x + dx, y + dy);
            if (c == null || !c.hasZombie) continue;

            var d = distance(c);
            if (d < dist)
              dist = d;
          }

      if (dist >= 3)
        screen.fillStyle = "#333333";
      else if (dist == 2)
        screen.fillStyle = "green";
      else if (dist == 1)
        screen.fillStyle = "yellow";
      else if (dist == 0)
        screen.fillStyle = "red";

      screen.fillRect(3 + x * UI.cellSize, 2 + y * UI.cellSize,
        UI.cellSize, UI.cellSize);
    }


// find distance from this cell to another
  public function distance(c: Cell): Int
    {
      var dx = x - c.x;
      var dy = y - c.y;
      return Std.int(Math.sqrt(dx * dx + dy * dy));
    }


// activate a cell
  public function activate()
    {
      if (!isVisible)
        {
          game.turns++;
          ui.paintStatus();
        }

      if (type == "obelisk" && isVisible)
        activateObelisk();

      alertNearbyZombies(true);
      if (game.isFinished)
        return;

      // clicking on a visible cell will lure nearby alerted creatures
      if (isVisible)
        {
          lureCreatures();
          return;
        }

      isVisible = true;

      // repaint map around
      game.map.paint(UI.getRect(x, y, 1));

      // check for death or finish
      if (hasZombie)
        game.finish(false);
      else game.checkFinish();

      game.map.revealCloseObelisks(this);
    }


// lure one of nearby alerted creatures to this cell
  public function lureCreatures()
    {
      if (!isWalkable()) return;

      for (i in 0...8)
        {
          var c = map.get(x + dx[i], y + dy[i]);
          if (c == null || !c.hasZombie || !c.zombieAlerted)
            continue;

          // move creature
          c.hasZombie = false;
          if (c.x > map.width / 3)
            c.isVisible = false;
          hasZombie = true;
          zombieAlerted = c.zombieAlerted;

          c.repaint();
          repaint();
          break;
        }      
    }


// helper: alert nearby zombies on activation
  public function alertNearbyZombies(killPlayerIfAlerted: Bool)
    {
      // did not pass through, zombies not alerted
      if (!isWalkable() || isVisible)
        return;

      // alert zombie if nearby
      for (i in 0...8)
        {
          var c = map.get(x + dx[i], y + dy[i]);
          if (c == null || !c.hasZombie) continue;
      
          // if zombie already alerted, death
          if (c.hasZombie && c.zombieAlerted && killPlayerIfAlerted)
            {
              ui.msg("You fail trying to sneak around the creature.");
              game.finish(false);
              return;
            }

          c.zombieAlerted = true;
          c.isVisible = true;

          // paint cell
          game.map.paint(UI.getRect(c.x, c.y, 0));
        }
    }


// obelisk activation
  public function activateObelisk()
    {
      ui.msg("Thunderous bolts of lightning shatter the obelisk.");
      type = "shatteredObelisk";

      // open cells around killing zombies
      for (i in 0...8)
        {
          var c = map.get(x + dx[i], y + dy[i]);
          if (c == null) continue;

          c.hasZombie = false;

          // explosion alerts zombies
          c.alertNearbyZombies(false);

          c.isVisible = true;
        }

      ui.paintStatus();

      // repaint map around
      game.map.paint(UI.getRect(x, y, 2));

      game.checkFinish();
    }


// has adjacent visible cells?
  public function hasAdjacentVisible()
    {
      for (i in 0...4)
        {
          var c = map.get(x + dx[i], y + dy[i]);
          if (c == null || !c.isVisible)
            continue;

          return true;
        }
      return false;
    }


// is cell walkable?
  public inline function isWalkable(): Bool
    {
      return Reflect.field(walkable, type);
    }


// has adjacent walkable (and visible) cells?
  public function hasAdjacentWalkable()
    {
      for (i in 0...8)
        {
          var c = map.get(x + dx[i], y + dy[i]);
          if (c == null || !c.isWalkable() || !c.isVisible)
            continue;

          return true;
        }
      return false;
    }


// repaint only this cell
  public inline function repaint()
    {
      game.map.paint(UI.getRect(x, y, 0));
    }


// get cell description
  public function getNote(): String
    {
      var s = "";
      if (hasZombie)
        s = "creature" + (zombieAlerted ? " (alerted)" : "");
      else if (Reflect.hasField(Cell.names, type))
        s = Reflect.field(Cell.names, type);
      else s = type;

      return s;
    }
}
