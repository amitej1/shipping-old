require 'base64'
require 'fileutils'
require 'tempfile'
require 'active_shipping'

include ActiveMerchant::Shipping

class OrdersController < ApplicationController
	SAVE_LABEL_LOCATION = "/home/amitej/shipping-old-1/shipping/labels"
	UPS_ORIGIN_NUMBER = "E44W84"
	TESTING = true

	
	def new
		 @order = Order.new
	end

	 

   
  

	def create
		# debugger
		 @order = Order.new
		 @sender_address = Address.new
		 @sender_address.city = params[:order][:origin][:city]
		 @sender_address.state = params[:order][:origin][:state]
		 @sender_address.zipcode = params[:order][:origin][:zipcode]
		 @sender_address.country = params[:order][:origin][:country]
		 @sender_address.save
		 @destination_address = Address.new
		 @destination_address.city = params[:order][:destination][:city]
		 @destination_address.state = params[:order][:destination][:state]
		 @destination_address.zipcode = params[:order][:destination][:zipcode]
		 @destination_address.country = params[:order][:destination][:country]
		 @destination_address.save
		 @order.length = params[:order][:length]
		 @order.width = params[:order][:width]
		 @order.height = params[:order][:height]
		 @order.weight = params[:order][:weight]
		 @order.origin_id = @sender_address.id
		 @order.destination_id = @destination_address.id
		 
		 @packages = [
  Package.new(  (@order.weight * 16),                 # 7.5 lbs, times 16 oz/lb.
                [@order.length, @order.width, @order.height],              # 15x10x4.5 inches
                :units => :imperial)        # not grams, not centimetres

  
]

# You live in Beverly Hills, he lives in Ottawa
# @origin = Location.new(      :country => @sender_address.country,
#                             :postal_code => @sender_address.zipcode)

# @destination = Location.new( :country => @destination_address.country,
#                             :postal_code => @destination_address.zipcode)

@origin = Location.new(     :origin_name => "Shan",
							:phone => '5555555555', 
							:country => 'US',
                            :state => 'CA',
                            :city => 'Beverly Hills',
                            :zip => '90210',
                            :origin_number => 'E44W84')

@destination = Location.new(:name => "ccc",
							:phone => '4444444444', 
							:country => 'CA',
                            :province => 'ON',
                            :city => 'Ottawa',
                            :postal_code => 'K1P 1J1')


 #used for generating labels
 @options = {
 	       :origin => {
 	          :address_line1 => "1 Arena Plaza", 
           :country => @sender_address.country, 
           :state => @sender_address.state,
           :city => @sender_address.city,
           :zip => @sender_address.zipcode, 
           :phone => "(502) 555-1212", 
           :name => "My Destination Name", 
           :attention_name => "Receiving Department", 
           :origin_number => UPS_ORIGIN_NUMBER
         }, 
         :destination => {
           :company_name => "Acme Co. Ltd.",
           :attention_name => "John Smith",
           :phone => "(555) 555-5555", 
           :address_line1 => "1234 No Street", 
           :country => @destination_address.country, 
           :state => @destination_address.state, 
           :city => @destination_address.city, 
           :zip => @destination_address.zipcode
           },
           :test => TESTING 
         
       }
	    
#options[:origin] = origin
#options[:destination] = destination


# Find out how much it'll be.



		check_shipment
	end
	def index
		@orders = Order.all
	end
	def show
		@order = Order.find(params[:id])
	end
	def edit
		 @order = Order.find(params[:id])
	end

	def check_shipment
		@ups1 = UPS.new(:login => 'tradeyaapp', :password => 'tradeyarules1!', :key => '7CC62503E9716786')
		response = @ups1.find_rates(@origin, @destination, @packages)

label_specification =  {:print_code => "GIF", :format_code => "GIF", :user_agent => "Mozilla/4.5"}
 @services = UPS::DEFAULT_SERVICES["03"]
 @ups_rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
 # debugger
 # @label = @ups.obtain_shipping_labels(@beverly_hills, @new_york, @packages,{:test => true, :origin_account => 'E44W84', :origin_name => 'tradeyaapp'})
@order.shipping_price = (@ups_rates[0][1].to_f)/100
# debugger
confirm_response = @ups1.shipment_confirmation_request("03", @packages, label_specification, @options)
# debugger
accept_response = @ups1.shipment_accept_request(confirm_response.digest)
# debugger



		

		 
accept_response.shipment_packages.each do |package|

		 html_image = package.html_image 
		  graphic_image = package.graphic_image 
		  label_image_format = package.label_image_format
		  tracking_number = package.tracking_number 
		  label_tmp_file = Tempfile.new("shipping_label")
		  # debugger
      decode_base64_content = Base64.decode64(graphic_image)
      File.open(label_tmp_file, "wb") do |f|
  		f.write(decode_base64_content)
		end
      #label_tmp_file.write(graphic_image)
      label_tmp_file.rewind
      html_tmp_file = Tempfile.new("shipping_label_html")
      #html_tmp_file.write Base64.decode64(html_image)
      #html_tmp_file.write(html_image)
      decode_base64_content_html = Base64.decode64(html_image)
      File.open(html_tmp_file, "wb") do |f|
  		f.write(decode_base64_content_html)
		end
      html_tmp_file.rewind
      graphic_filename = "#{SAVE_LABEL_LOCATION}/label#{tracking_number}.#{label_image_format.downcase}"
      gf = File.new(graphic_filename, "wb")
      gf.write File.new(label_tmp_file.path).read
      gf.close
      html_filename = "#{SAVE_LABEL_LOCATION}/#{tracking_number}.html"
      hf = File.new(html_filename, "wb")
      hf.write File.new(html_tmp_file.path).read
      hf.close
  end

# debugger
	 @order.save
	 redirect_to @order	
	end
end

