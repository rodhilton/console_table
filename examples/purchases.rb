require 'console_table'
require 'faker'
require 'colorize'

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

ConsoleTable.define(layout, :title=>"Product Purchases".green.bold.underline) do |table|
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
			profit.to_s.colorize(profit < 0 ? :red : :green)
		]

		sleep(1)
	end
end