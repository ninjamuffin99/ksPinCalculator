package;

import format.csv.*;
import format.csv.Data.Csv;
import format.csv.Data.Record;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;

using StringTools;

class Main
{
	// todo
	// seperate functions for bullshit
	// get shipping country
	// create new csv with only the data needed
	public static var QUICKSHIT:String = 'PinsPosters';
	public static var infoRow:Record;

	static function main():Void
	{
		trace("PARSING CSV DATA");
		var csv:String = "";

		if (FileSystem.exists('input/ks${QUICKSHIT}.csv'))
		{
			csv = File.getContent('input/ks${QUICKSHIT}.csv');
			trace("Found quicker file!");
		}
		else
		{
			csv = File.getContent('input/ks.csv');
		}

		var csvData:Csv = Reader.parseCsv(csv, ',');

		infoRow = csvData.shift();

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

		pinCounter = countRewards(csvData, [rewardPin, rewardPoster], [15, 19]);

		trace(pinCounter + " PINS");
		trace(userWitPinOrPoster + " USERS WITH PINS OR POSTERS");
		trace(pinAndPoster + " USERS WITH PINS AND POSTERS");
		var onlyOne:Int = userWitPinOrPoster - pinAndPoster;
		trace(onlyOne + " USERS WITH ONLY A PIN OR A POSTER");
	}

	public static function countRewards(csv:Csv, tiers:Array<String>, addonsArray:Array<Int>):Int
	{
		var inc:Int = 0;

		function getMapSum(daMap:Map<Int, Int>):Int
		{
			var output:Int = 0;
			for (num in daMap)
			{
				output += num;
			}

			return output;
		}

		var csvOutput:Csv = new Csv();

		for (i in 0...csv.length)
		{
			var backer:Record = csv[i];
			var tier:String = backer[6].toLowerCase().trim();

			var pinUnparsed:String = backer[15];
			var pins:Int = Std.parseInt(pinUnparsed);

			var posters:Int = Std.parseInt(backer[19]);

			var addonMap:Map<Int, Int> = new Map();

			for (addon in addonsArray)
				addonMap[addon] = Std.parseInt(backer[addon]); // initialize

			if (getMapSum(addonMap) > 0 || tiers.contains(tier))
			{
				// trace('HAS TIER OR ADDON!');

				csvOutput.push(backer);

				// userWitPinOrPoster++;
				// has pins as addon

				// if ((pins > 0 || tier == rewardPin) && (posters > 0 || tier == rewardPoster))
				// {
				// pinAndPoster++;
				// }
			}

			inc += Std.parseInt(backer[15]);
		}

		csvOutput.unshift(infoRow);

		if (!FileSystem.exists('input/ks${QUICKSHIT}.csv'))
		{
			trace("WRITING NEW CSV FILE");
			File.saveContent('input/ks${QUICKSHIT}.csv', Dsv.encode(csvOutput, {
				delimiter: ',',
				quote: '"',
				escapedQuote: '""',
				newline: "\n"
			}));
			trace("FINISHED WRITING CSV FILE!");
		}

		return inc;
	}

	static function parseCSVtoString(csvOutput:Csv):String
	{
		var fin:String = "";

		for (record in csvOutput)
		{
			var bullshit:String = record.toString();
			bullshit = bullshit.substr(1, bullshit.length - 2);
			fin += bullshit + "\n";
		}

		return fin;
	}
}

typedef Backer =
{
	BackerNum:Int
}

typedef BullshitOutput =
{
	Single:Int,
	EitherOr:Int,
	Both:Int
}
