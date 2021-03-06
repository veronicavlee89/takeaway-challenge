require 'takeaway_service'

describe TakeawayService do
  subject(:takeaway) { TakeawayService.new(twilio_dbl, restaurant_dbl) }
  let(:twilio_dbl) { double('twilio') }
  let(:restaurant_dbl) { double('restaurant', format_menu: formatted_menu) }
  let(:formatted_menu) { "Mock example\nof a\nformatted menu" }
  let(:order_dbl) { double('order', basket: [{ dish: dish_dbl1, qty: 2 }, { dish: dish_dbl2, qty: 1 }], total: 27.98) }
  let(:dish_dbl1) { double('dish', name: 'Pepperoni pizza', price: 8.99) }
  let(:dish_dbl2) { double('dish', name: 'Lasagne', price: 10.00) }
  let(:to_phone) { '+44007701234567' }

  it 'sets the sms_service' do
    expect(takeaway.sms_service).to eq(twilio_dbl)
  end

  it 'sets the restaurant' do
    expect(takeaway.restaurant).to eq(restaurant_dbl)
  end

  describe '#print_menu' do
    it "sends a format_menu message to the restaurant" do
      expect(restaurant_dbl).to receive(:format_menu).once
      takeaway.print_menu
    end

    it "prints the formatted menu received from restaurant" do
      expected = "#{formatted_menu}\n"
      expect { takeaway.print_menu }.to output(expected).to_stdout
    end
  end

  describe '#create_order(order = Order.new())' do
    it 'creates a new Order object if none provided' do
      expect(Order).to receive(:new).once.with(restaurant_dbl)
      takeaway.create_order
    end

    it 'returns the order object' do
      expect(takeaway.create_order(order_dbl)).to eq(order_dbl)
    end
  end

  describe '#place_order(order, customer_phone)' do
    it 'takes an order as an argument' do
      expect(takeaway).to respond_to(:place_order).with(2).arguments
    end

    it 'raises an error if the total on the order is incorrect' do
      allow(order_dbl).to receive(:total).and_return(12.00)
      allow(restaurant_dbl).to receive(:find_dish).with(dish_dbl1.name).and_return(dish_dbl1)
      allow(restaurant_dbl).to receive(:find_dish).with(dish_dbl2.name).and_return(dish_dbl2)

      expect { takeaway.place_order(order_dbl, to_phone) }.to raise_error(RuntimeError)
    end

    it 'sends a send_sms message to sms_service with phone no. and message' do
      allow(restaurant_dbl).to receive(:find_dish).with(dish_dbl1.name).and_return(dish_dbl1)
      allow(restaurant_dbl).to receive(:find_dish).with(dish_dbl2.name).and_return(dish_dbl2)
      allow(Time).to receive(:now).and_return(Time.parse("2020-09-13 17:52:20"))

      message = 'Thank you! Your order was placed and will be delivered before 6:52PM'

      expect(twilio_dbl).to receive(:send_sms).once.with(to_phone, message)
      takeaway.place_order(order_dbl, to_phone)
    end
  end
end
