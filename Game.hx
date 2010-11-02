// game class

class Game
{
  public var ui: UI;
  public var map: Map;
  public var turns: Int;
  public var zombies: Int;
  public var zombiesDestroyed: Int;
  public var isFinished: Bool;

  public function new()
    {
      ui = new UI(this);
      map = new Map(this);
     
      var hasPlayed = ui.getVar('hasPlayed');
      if (hasPlayed == null)
        ui.alert("Welcome to Black Obelisk.<br><br>" +
          "If this is your first time playing, please take the time to read the " +
          "<a target=_blank href='http://code.google.com/p/bobelisk/wiki/Manual'>Manual</a> before playing.");
      ui.setVar('hasPlayed', '1');

      restart();
    } 

// main function
  static var instance: Game;
  static function main()
    {
      instance = new Game();
    }


// finish the game
  public function finish(isVictory: Bool)
    {
      isFinished = true;
      ui.track((isVictory ? "winGame" : "loseGame"),
        "", turns);
      ui.finish(isVictory);
    }


// check for victory
  public function checkFinish()
    {
      // check if all obelisks are shattered
      if (map.obelisksShattered() < map.obelisks.length)
        return;

      finish(true);
    }


// restart game
  public function restart()
    {
      ui.track("startGame");
      isFinished = false;
      turns = 0;
      zombies = 0;
      zombiesDestroyed = 0;
      map.generate();
      map.paint();
      ui.paintStatus();
    }


  public static var version = "v2"; // game version
}
