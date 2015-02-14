require 'console_table'

require 'json'
require 'net/http'
require 'open-uri'
require 'colorize'

symbols = ["YHOO", "AAPL", "GOOG", "MSFT", "C", "MMM", "KO", "WMT", "GM", "IBM", "MCD", "VZ", "HD", "DIS", "INTC"]

params = symbols.collect{|s| "\"#{s}\"" }.join(",")
url = "http://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quotes where symbol in (#{params})&env=http://datatables.org/alltables.env&format=json"
uri = URI.parse(URI::encode(url))
response = Net::HTTP.get_response(uri)
json = JSON.parse(response.body)

table_config = [
    {:key=>:symbol, :title=>"Symbol", :size=>6},
    {:key=>:name, :title=>"Name", :size=>17},
    {:key=>:price, :title=>"Price", :size=>5, :justify=>:right},
    {:key=>:change, :title=>"Change", :size=>7, :justify=>:right},
    {:key=>:recommendation, :title=>"Recommendation", :size=>15, :justify=>:right}
]

ConsoleTable.define(table_config, :title=>"Stock Prices") do |table|

    json["query"]["results"]["quote"].each do |j|
        change = j["ChangeRealtime"]
        if change.start_with?("+")
            change = change.green
        else
            change = change.red
        end

        recommendation = (rand() <= 0.5) ? "BUY!".white.on_green.bold.underline : "Sell".yellow

        table << [
            j["Symbol"].magenta,
            j["Name"],
            j["LastTradePriceOnly"],
            change,
            recommendation
        ]

    end

    table.footer << "Recommendations randomly generated"

end