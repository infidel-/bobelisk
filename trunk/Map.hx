// map class

class Map
{
  var ui: UI;
  var game: Game;

  var cells: Hash<Cell>;
  public var obelisks: List<Cell>;
  public var width: Int;
  public var height: Int;

  public function new(g: Game)
    {
      game = g;
      ui = game.ui;
      width = UI.mapWidth;
      height = UI.mapHeight;
    }


// generate map
  public function generate()
    {
      cells = new Hash<Cell>();
      obelisks = new List<Cell>();

      // clean field
      for (y in 0...height)
        for (x in 0...width)
          {
            var cell = new Cell(game);
            cell.x = x;
            cell.y = y;
            cell.type = "grass";
            cells.set(x + "," + y, cell);
          }

      // terrain generator
      for (y in 0...height)
        for (x in 0...width)
          {
            var cell = get(x,y);
            if (cell.x < width / 3)
              {
                if (Math.random() < 0.05)
                  cell.type = "tree";

                cell.isVisible = true;
              }
            else
              {
                if (Math.random() < 0.9)
                  cell.type = "swamp";
                if (Math.random() < 0.2)
                  cell.type = "water";
                if (Math.random() < 0.05)
                  cell.type = "tree";
                cell.isVisible = false;
              }
//            cell.isVisible = true;

            if (cell.x == 1 + Std.int(width / 3) && Math.random() < 0.3)
              cell.type = "grass";

            if (cell.x >= width / 3 &&
                (cell.type == "grass" || cell.type == "swamp") &&
                Math.random() < 0.07)
              cell.hasZombie = true;

            cells.set(x + "," + y, cell);
          }

      for (c in cells) // count number of creatures
        if (c.hasZombie)
          game.zombies++;
  
      generateObelisks();
      generateBuildings();
    }


// generate obelisks
  function generateObelisks()
    {
      var numObelisks = 3 + Std.int(4 * Math.random());

      for (i in 0...numObelisks)
        {
          var x = Std.int(2 * width / 3 + Math.random() * width / 3 - 1);
          var y = Std.int(height * Math.random());

          var cell = get(x, y);
          cell.type = "obelisk";
          cell.hasZombie = false;
          obelisks.add(cell);
        }
    }


// generate buildings
  function generateBuildings()
    {
      // buildings
      for (y in 0...height)
        for (x in 0...Std.int(width / 3))
          {
            var cell = get(x,y);
            if (Math.random() > 0.05)
              continue;

            // size
            var sx = 2 + Std.int(Math.random() * 2);
            var sy = 2 + Std.int(Math.random() * 2);

            // check for adjacent buildings
            var ok = true;
            for (dy in -1...sy + 2)
              for (dx in -1...sx + 2)
                {
                  if (dx == 0 && dy == 0)
                    continue;
                  var cell = get(x + dx, y + dy);
                  if (cell != null && cell.type == "building")
                    {
                      ok = false;
                      break;
                    }
                }

            if (!ok)
              continue;

            for (dy in 0...sy)
              for (dx in 0...sx)
                {
                  var cell = get(x + dx, y + dy);
                  if (cell == null)
                    continue;
                  cell.type = "building";
                }
            cells.set(x + "," + y, cell);
          }
    }


// paint map
  public function paint(?rect: Dynamic)
    {
      var el = untyped UI.e("map");
      var map = el.getContext("2d");
      map.font = UI.cellSize + "px Verdana";
      map.fillStyle = "black";
      map.textBaseline = "top";
      if (rect == null)
        rect = { x: 0, y: 0, w: 1000, h: 740};
      if (rect.x < 0)
        rect.x = 0;
      if (rect.y < 0)
        rect.y = 0;
      map.fillRect(rect.x, rect.y, rect.w, rect.h);

      for (y in 0...height)
        for (x in 0...width)
          {
            var cell = get(x, y);
            cell.paint(map,
              (ui.cursorX == x && ui.cursorY == y), rect);
          }
    }


  public function get(x: Int, y: Int): Cell
    {
      return cells.get(x + "," + y);
    }


// number of found obelisks
  public function obelisksFound(): Int
    {
      var cnt = 0;
      for (o in game.map.obelisks)
        if (o.isVisible)
          cnt++;
      return cnt;
    }


// number of shattered obelisks
  public function obelisksShattered(): Int
    {
      var cnt = 0;
      for (o in game.map.obelisks)
        if (o.isVisible && o.type == "shatteredObelisk")
          cnt++;
      return cnt;
    }


// show close obelisks
  public function revealCloseObelisks(cell: Cell)
    {
      var map = untyped UI.e("map").getContext("2d");

      // check for distance to obelisks
      for (o in obelisks)
        {
          // too far
          if (o.isVisible || cell.distance(o) > 5)
            continue;

          var fx = o.x - 1 + Std.int(Math.random() * 2);
          var fy = o.y - 1 + Std.int(Math.random() * 2);
          map.fillStyle = Cell.colors.fakeObelisk;
          map.fillText(Cell.symbols.fakeObelisk,
            5 + fx * UI.cellSize, -1 + fy * UI.cellSize);
        }
    }
}
