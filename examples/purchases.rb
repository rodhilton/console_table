require 'console_table'
require 'faker'
require 'colorize'

# Just a goofy example that simulates a big table of purchase data.

layout = [
	{size: 6, title: "Pur.#"},
	{size: 20, title: "Customer"},
	{size: 13, title: "Product Code"},
	{size: "*", title: "Product Name", ellipsize: true},
	{size: 5, title: "Price", justify: :right},
	{size: 3, title: "Qty"},
	{size: 8, title: "Date"},
	{size: 11, title: "Profit/Loss", justify: :right}
]

sum = 0

ConsoleTable.define(layout, :title=>"Product Purchases".upcase.bold.green.underline) do |table|
	(0..25).each do |i|
		name = Faker::Name.name
		profit = (rand(1*100000)-30000)/100.00
		table << [
			sprintf("%010d", rand(1..999999999)).blue,
			name,
			Faker::Code.ean.red,
			Faker::Commerce.product_name,
			sprintf("%#.2f", Faker::Commerce.price).bold.green,
			rand(1..20).to_s.magenta,
			Faker::Date.backward(14).strftime("%m/%d/%y").yellow,
			sprintf("%#.2f", profit).colorize(profit < 0 ? :red : :green)
		]

		sum = sum + profit

		sleep(rand(1..10)/20.0)
	end

	table.footer << "Total Profit: #{sprintf("%#.2f", sum).to_s.colorize(sum < 0 ? :red : :green)}"
end