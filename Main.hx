import format.csv.Data.Csv;
import format.csv.Data.Record;
import sys.io.File;
import format.csv.*;

using StringTools;

class Main
{
	static function main():Void
	{
		trace("PARSING CSV DATA");
		var csv:String = File.getContent('input/ks.csv');
		var csvData:Csv = Reader.parseCsv(csv, ',');

		var infoRow:Record = csvData.shift();

		var ksBackerMap:Map<String, Int> = new Map();
		trace("KS SHIIIT");
		for (index => item in infoRow)
		{
			ksBackerMap[item] = index;
			trace(item + " :===: " + index);
		}

		var pinCounter:Int = 0;
		var userWitPinOrPoster:Int = 0;
		var pinAndPoster:Int = 0;

		var rewardPoster:String = "friday night funkin poster";
		var rewardPin:String = "enamel pin";

		for (i in 0...csvData.length)
		{
			var backer:Record = csvData[i];
			var tier:String = backer[6].toLowerCase().trim();

			var pinUnparsed:String = backer[15];
			var pins:Int = Std.parseInt(pinUnparsed);

			var posters:Int = Std.parseInt(backer[19]);

			if (pins > 0 || posters > 0 || tier == rewardPin || tier == rewardPoster)
			{
				userWitPinOrPoster++;
				// has pins as addon

				if ((pins > 0 || tier == rewardPin) && (posters > 0 || tier == rewardPoster))
				{
					pinAndPoster++;
				}
			}

			pinCounter += Std.parseInt(backer[15]);
		}

		trace(pinCounter + " PINS");
		trace(userWitPinOrPoster + " USERS WITH PINS OR POSTERS");
		trace(pinAndPoster + " USERS WITH PINS AND POSTERS");
		var onlyOne:Int = userWitPinOrPoster - pinAndPoster;
		trace(onlyOne + " USERS WITH ONLY A PIN OR A POSTER");
	}
}

typedef Backer =
{
	BackerNum:Int
}
