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
	public static var QUICKSHIT:String;
	public static var infoRow:Record;

	public static var curConfig:Config;

	static function main():Void
	{
		trace("PARSING CSV DATA");

		curConfig = parseTxtArray('rewardTierConfigs/coby.json');
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

		traceKickstarterMap();

		var funnyCounter:BullshitOutput = {Both: 0, Single: 0, EitherOr: 0};

		funnyCounter = countRewards(csvData, curConfig.tiers, curConfig.addons);

		trace(funnyCounter.Single + " PINS");
		trace(funnyCounter.EitherOr + " USERS WITH PINS OR POSTERS");
		trace(funnyCounter.Both + " USERS WITH PINS AND POSTERS");
		var onlyOne:Int = funnyCounter.EitherOr - funnyCounter.Both;
		trace(onlyOne + " USERS WITH ONLY A PIN OR A POSTER");

		addressExport(csvData);
	}

	public static function addressExport(csv:Csv)
	{
		var header:Record = new Record();

		for (stuff in curConfig.outputStuff)
			header.push(getOutputForm(stuff));

		var csvOutput:Csv = new Csv();

		csvOutput.push(header);

		var noAddress:Array<Record> = [];
		noAddress.push(infoRow);

		for (backer in csv)
		{
			var backerOutput:Record = new Record();

			if (backer[43] == "" && backer[44] == "")
			{
				noAddress.push(backer);

				continue;
			}

			var itemsList:Array<String> = [];
			itemsList.push("");

			var backerMap:Map<Int, Int> = countBackerReward(backer);

			for (prodKey in backerMap.keys())
			{
				if (QUICKSHIT == "NeedleJuice")
				{
					if (backerMap[prodKey] > 0)
					{
						itemsList[0] += "product_id:" + prodKey + "|quantity:" + backerMap[prodKey] + "|total:0;";
					}
				}
				if (QUICKSHIT == "PinsPosters")
				{
					if (backerMap[prodKey] > 0)
					{
						// trace('SWAG UP: ' + backerMap[prodKey] + " " + prodKey);
						itemsList[itemsList.length - 1] = Std.string(prodKey);
						itemsList.push("");
						// itemsList[0] += "product_id:" + prodKey + "|quantity:" + backerMap[prodKey] + "|total:0;";
					}
				}
			}

			if (itemsList[0] == "")
			{
				// trace("NO ITEMS???");
				// did not have any items in this tier
				continue;
			}

			for (i in 0...header.length)
			{
				var prefillStr:String = curConfig.outputStuff[i];
				var prefill:Int = getOutputPrefill(prefillStr);

				if (prefill != null)
				{
					// trace("PREFILL WROK");
					backerOutput.push(backer[prefill]);
				}
				else
				{
					// trace("OUTPUT LOL!");
					switch (header[i])
					{
						case "Includes Pin Set?":
							// backerOutput.push("PINS");
							for (item in itemsList)
							{
								if (item == getProdId(curConfig.productIDs[0]))
									backerOutput.push(Std.string(backerMap[Std.parseInt(item)]));
							}
						case "Includes Poster?":
							// backerOutput.push('POSTER');
							for (item in itemsList)
							{
								if (item == getProdId(curConfig.productIDs[1]))
									backerOutput.push(Std.string(backerMap[Std.parseInt(item)]));
							}

						case "order_total":
							backerOutput.push("0");
						case "shipping_total":
							backerOutput.push("0");
						case "shipping_items":
							backerOutput.push('method_id:flat_rate|total:0');
						case "customer_note":
							var output:String = backer[0];
							output += " - Shipping note: " + backer[51];

							backerOutput.push(output);
						case "line_items":
							backerOutput.push(itemsList[0]);

						default:
							backerOutput.push("");
					}
				}
			}

			csvOutput.push(backerOutput);
		}

		trace(noAddress.length + " BACKERS WITH NO ADDRESS!!!");

		File.saveContent('output/noAddress-' + curConfig.quickShit + ".csv", Dsv.encode(noAddress, {
			delimiter: ',',
			quote: '"',
			escapedQuote: '""',
			newline: "\n"
		}));

		File.saveContent('output/addressOutput-' + curConfig.quickShit + ".csv", Dsv.encode(csvOutput, {
			delimiter: ',',
			quote: '"',
			escapedQuote: '""',
			newline: "\n"
		}));
	}

	static function countBackerReward(backer:Record):Map<Int, Int>
	{
		var productMap:Map<Int, Int> = new Map();

		for (product in curConfig.productIDs)
		{
			var prodID:Int = Std.parseInt(product.split(' - ')[1]);
			productMap[prodID] = 0;
		}

		var tierMap:Map<String, Array<Int>> = new Map();

		for (index => tier in curConfig.tiers)
		{
			tierMap[tier] = curConfig.tierInc[index];
		}

		if (tierMap[backer[6].toLowerCase()] != null)
		{
			for (prod in tierMap[backer[6].toLowerCase()])
				productMap[prod] += 1;
		}

		// trace(tierMap[backer[6].toLowerCase()]);

		/* 	for (index => tier in curConfig.tiers)
			{
				if (backer[6].trim() == tier)
				{
					trace('FOUND TIER: ' + tier);
					for (prod in curConfig.tierInc[index])
						productMap[prod] += 1;
				}
		}*/

		for (index => addon in curConfig.addonInc)
		{
			var products:Array<Int> = addon[1];

			for (prod in products)
			{
				productMap[prod] += Std.parseInt(backer[addon[0]]);
			}
		}

		return productMap;

		// trace(backer[0] + " - " + productMap);
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

				if (tier == tiers[1])
					daOutput.Single += 1;

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

	static function traceKickstarterMap()
	{
		var ksBackerMap:Map<String, Int> = new Map();
		trace("KS SHIIIT");
		for (index => item in infoRow)
		{
			ksBackerMap[item] = index;
			trace(item + " :===: " + index);
		}
	}

	static function getOutputForm(outputField:String):String
	{
		return outputField.split(":")[0];
	}

	static function getOutputPrefill(outputField:String):Int
	{
		return Std.parseInt(outputField.split(':')[1]);
	}

	static function formatProductID(productString:String):String
	{
		return "product_id:" + getProdId(productString); // anything after "- ", which is the number as a string;
	}

	static function getProdId(prodstring:String):String
	{
		return prodstring.split(" - ")[1];
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
	addons:Array<Int>,
	productIDs:Array<String>,
	outputStuff:Array<String>,
	tierInc:Array<Array<Int>>,
	addonInc:Array<Dynamic>
}
