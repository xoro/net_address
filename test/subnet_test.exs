defmodule IPTest.IPSubnetTest do
  use ExUnit.Case, async: true
  doctest IP.Subnet

  alias IP.Subnet
  import IP

  describe "new/2" do
    test "the basics work" do
      assert %Subnet{
               routing_prefix: ~i"10.0.0.0",
               bit_length: 24
             } == Subnet.new(~i"10.0.0.0", 24)
    end

    test "function clause errors if the routing prefix isn't an ip address" do
      assert_raise FunctionClauseError, fn -> Subnet.new("foo", 24) end
    end

    test "function clause errors if the bit length doesn't match the ip address size" do
      assert_raise FunctionClauseError, fn -> Subnet.new(~i"10.0.0.0", -1) end
      assert_raise FunctionClauseError, fn -> Subnet.new(~i"10.0.0.0", 33) end
    end

    test "argument errors if the routing prefix isn't the proper root" do
      assert_raise ArgumentError, fn -> Subnet.new(~i"10.0.0.1", 24) end
    end
  end

  describe "of/2" do
    test "the basics work" do
      assert %Subnet{
               routing_prefix: ~i"10.0.0.0",
               bit_length: 24
             } == Subnet.of(~i"10.0.0.3", 24)
    end

    test "function clause errors if the routing prefix isn't an ip address" do
      assert_raise FunctionClauseError, fn -> Subnet.of("foo", 24) end
    end

    test "function clause errors if the bit length doesn't match the ip address size" do
      assert_raise FunctionClauseError, fn -> Subnet.of(~i"10.0.0.0", -1) end
      assert_raise FunctionClauseError, fn -> Subnet.of(~i"10.0.0.0", 33) end
    end
  end

  describe "to_string/1" do
    test "works" do
      assert "10.0.0.0/24" = Subnet.to_string(~i"10.0.0.0/24")
    end
  end

  describe "from_string!/1" do
    test "correctly figures out an ipv4 subnet" do
      assert ~i"10.0.0.0/24" == Subnet.from_string!("10.0.0.0/24")
      assert ~i"10.0.0.0/24" == Subnet.from_string!("10.0.0.2/24")
      assert ~i"::1/24" == Subnet.from_string!("::1/24")
      assert ~i"::1/100" == Subnet.from_string!("::1/100")
    end

    test "raises an argument error if something strange is passed" do
      assert_raise ArgumentError, fn -> Subnet.from_string!("foo") end
      assert_raise ArgumentError, fn -> Subnet.from_string!("10.0.0.2") end
      assert_raise ArgumentError, fn -> Subnet.from_string!("10.0.0.2/bar") end
      assert_raise ArgumentError, fn -> Subnet.from_string!("10.0.0.2/-1") end
      assert_raise ArgumentError, fn -> Subnet.from_string!("10.0.0.2/100") end
      assert_raise ArgumentError, fn -> Subnet.from_string!(:foo) end
    end
  end

  describe "inspecting the Subnet struct" do
    test "works as expected" do
      assert ~s(~i"10.0.0.0/24") ==
               inspect(%Subnet{
                 routing_prefix: {10, 0, 0, 0},
                 bit_length: 24
               })
    end
  end

  describe "type/1" do
    test "correctly identifies ipv4 subnet" do
      assert :v4 == Subnet.type(~i"10.0.0.0/24")
    end
  end

  describe "config_from_string/1" do
    test "raises when invalid values are presented" do
      assert_raise ArgumentError, fn ->
        Subnet.config_from_string!("10.0.1.1.1/24")
      end

      assert_raise ArgumentError, fn ->
        Subnet.config_from_string!("10.0.1000.1/24")
      end

      assert_raise ArgumentError, fn ->
        Subnet.config_from_string!("10.0.0.1/150")
      end

      assert_raise ArgumentError, fn ->
        Subnet.config_from_string!("not_an_ip_address")
      end

      assert_raise ArgumentError, fn ->
        Subnet.config_from_string!("10.0.0.0")
      end

      assert_raise ArgumentError, fn ->
        Subnet.config_from_string!(:foo)
      end
    end
  end

  # GUARD TEST

  require Subnet

  describe "is_subnet/1" do
    test "works on basic subnets" do
      assert Subnet.is_subnet(~i"10.0.0.0/24")
    end

    test "fails if it's not a proper struct" do
      refute Subnet.is_subnet(:foo)

      refute Subnet.is_subnet(%{
               routing_prefix: ~i"10.0.0.0",
               bit_length: -1
             })
    end

    test "fails if subnet has invalid bit lengths" do
      refute Subnet.is_subnet(%Subnet{
               routing_prefix: ~i"10.0.0.0",
               bit_length: -1
             })

      refute Subnet.is_subnet(%Subnet{
               routing_prefix: ~i"10.0.0.0",
               bit_length: 46
             })
    end
  end

  describe "is_in/2" do
    test "works on fourth octet subnets" do
      assert Subnet.is_in(~i"10.0.0.0/26", ~i"10.0.0.1")
      refute Subnet.is_in(~i"10.0.0.0/26", ~i"10.0.0.127")
      refute Subnet.is_in(~i"10.0.0.16/28", ~i"10.0.0.12")
      assert Subnet.is_in(~i"10.0.0.0/24", ~i"10.0.0.1")
      assert Subnet.is_in(~i"10.0.0.0/24", ~i"10.0.0.255")
      refute Subnet.is_in(~i"10.0.0.0/24", ~i"10.0.1.0")
    end

    test "works on third octet subnets" do
      assert Subnet.is_in(~i"10.0.0.0/20", ~i"10.0.1.1")
      refute Subnet.is_in(~i"10.0.0.0/20", ~i"10.0.16.1")
      assert Subnet.is_in(~i"10.0.0.0/16", ~i"10.0.1.1")
      assert Subnet.is_in(~i"10.0.0.0/16", ~i"10.0.255.255")
      refute Subnet.is_in(~i"10.0.0.0/16", ~i"10.1.0.0")
    end

    test "works on second octet subnets" do
      assert Subnet.is_in(~i"10.0.0.0/12", ~i"10.7.0.1")
      refute Subnet.is_in(~i"10.0.0.0/12", ~i"10.16.0.1")
      assert Subnet.is_in(~i"10.0.0.0/8", ~i"10.1.1.1")
      assert Subnet.is_in(~i"10.0.0.0/8", ~i"10.255.255.255")
      refute Subnet.is_in(~i"10.0.0.0/8", ~i"11.0.0.0")
    end

    test "works on all octet subnets" do
      assert Subnet.is_in(~i"16.0.0.0/4", ~i"16.0.0.0")
      assert Subnet.is_in(~i"16.0.0.0/4", ~i"16.255.255.255")
      assert Subnet.is_in(~i"16.0.0.0/4", ~i"17.0.0.1")
      refute Subnet.is_in(~i"32.0.0.0/4", ~i"17.0.0.1")
      assert Subnet.is_in(~i"0.0.0.0/0", ~i"1.1.1.1")
      assert Subnet.is_in(~i"0.0.0.0/0", ~i"255.255.255.255")
    end
  end
end
