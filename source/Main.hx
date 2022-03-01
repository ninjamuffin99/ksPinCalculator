package;

import format.csv.*;
import format.csv.Data.Csv;
import format.csv.Data.Record;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

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

		var funnyCounter:BullshitOutput = {Both: 0, Single: 0, EitherOr: 0};

		var rewardPoster:String = "friday night funkin poster";
		var rewardPin:String = "enamel pin";

		var tierTxt:Array<String> = parseTxtArray('rewardTierConfigs/coby.json');

		for (t in tierTxt)
			t.trim();
		// trace(tierTxt);

		funnyCounter = countRewards(csvData, tierTxt, [15, 19]);

		trace(funnyCounter.Single + " PINS");
		trace(funnyCounter.EitherOr + " USERS WITH PINS OR POSTERS");
		trace(funnyCounter.Both + " USERS WITH PINS AND POSTERS");
		var onlyOne:Int = funnyCounter.EitherOr - funnyCounter.Both;
		trace(onlyOne + " USERS WITH ONLY A PIN OR A POSTER");
	}

	public static function countRewards(csv:Csv, tiers:Array<String>, addonsArray:Array<Int>):BullshitOutput
	{
		var daOutput:BullshitOutput = {Both: 0, EitherOr: 0, Single: 0};
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

			var addonMap:Map<Int, Int> = new Map();

			for (addon in addonsArray)
				addonMap[addon] = Std.parseInt(backer[addon]); // initialize

			if (getMapSum(addonMap) > 0 || tiers.contains(tier))
			{
				// trace('HAS TIER OR ADDON!');

				csvOutput.push(backer);

				daOutput.EitherOr++;
				// userWitPinOrPoster++;
				// has pins as addon

				var hasAddon:Bool = true;
				for (num in addonMap)
				{
					if (num == 0)
						hasAddon = false;
				}

				if (hasAddon)
				{
					daOutput.Both++;
				}

				// if ((pins > 0 || tier == rewardPin) && (posters > 0 || tier == rewardPoster))
				// {
				// pinAndPoster++;
				// }
			}

			daOutput.Single += Std.parseInt(backer[15]);
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

		return daOutput;
	}

	static function parseTxtArray(txt:String):Array<String>
	{
		return cast Json.parse(File.getContent(txt)).tiers;
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
