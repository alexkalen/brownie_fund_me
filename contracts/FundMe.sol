// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    //This is the first thing to run ina  contract
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // Set minimum to $50
        uint256 minimumUSD = 50 * 10**18;

        //To continue this function you require to:
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH"
        );

        //Mapping the adresses who are fundig and the amount
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Withdraw all funds from the contract
    function withdraw() public payable onlyOwner {
        //transfers all the 'balance' to the current address
        msg.sender.transfer(address(this).balance);

        //Remaps all the funders addresses to have 0 balance
        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    //Gets the current price of ETH -> USDT
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1000000000);
        //305132999637
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }
}
