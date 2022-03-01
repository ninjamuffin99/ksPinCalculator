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
	public static var QUICKSHIT:String;
	public static var infoRow:Record;

	public static var curConfig:Config;

	static function main():Void
	{
		trace("PARSING CSV DATA");

		curConfig = parseTxtArray('rewardTierConfigs/needle.json');
		QUICKSHIT = curConfig.quickShit;

		configTiersToLowercase();

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

		funnyCounter = countRewards(csvData, curConfig.tiers, curConfig.addons);

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

		var shippingMap:Map<String, Int> = new Map();
		var shippingBudget:Map<String, Float> = new Map();

		var csvOutput:Csv = new Csv();

		for (i in 0...csv.length)
		{
			var backer:Record = csv[i];
			var tier:String = backer[6].toLowerCase().trim();

			var country:String = backer[4];

			if (shippingBudget.exists(country))
				shippingBudget[country] += Std.parseFloat(backer[5].substr(1));
			else
				shippingBudget[country] = 0;

			if (shippingMap.exists(country))
				shippingMap[country] += 1;
			else
				shippingMap[country] = 0;

			var addonMap:Map<Int, Int> = new Map();

			for (addon in addonsArray)
				addonMap[addon] = Std.parseInt(backer[addon]); // initialize

			if (getMapSum(addonMap) > 0 || tiers.contains(tier))
			{
				csvOutput.push(backer);
				daOutput.EitherOr++;
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

		var countryOutput:String = "";

		for (shit in shippingMap.keys())
		{
			countryOutput += shit + " -- " + shippingMap[shit] + " $" + shippingBudget[shit] + "\n";
		}

		var daBudget:Float = 0;
		for (alsoShit in shippingBudget)
			daBudget += alsoShit;

		countryOutput += "DA FULL SHIPPING BUDGET: $" + daBudget;

		File.saveContent('output/shippingStuff.txt', countryOutput);

		return daOutput;
	}

	static function parseTxtArray(txt:String):Config
	{
		return cast Json.parse(File.getContent(txt));
	}

	static function configTiersToLowercase()
	{
		for (ind => tier in curConfig.tiers)
			curConfig.tiers[ind] = tier.toLowerCase();

		trace(curConfig.tiers);
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

typedef Config =
{
	quickShit:String,
	tiers:Array<String>,
	addons:Array<Int>
}
