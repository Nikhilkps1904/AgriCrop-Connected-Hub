// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedAuction {
    struct Item {
        uint id;
        address payable seller;
        string name;
        string imageUrl;
        uint minBid;
        uint buyoutPrice;
        uint auctionEndTime;
        address highestBidder;
        uint highestBid;
        bool ended;
    }

    struct User {
        string username;
        address walletAddress;
    }

    Item[] public items;
    mapping(address => User) public users;
    mapping(address => bool) public registered;

    event UserRegistered(address userAddress, string username);
    event AuctionCreated(uint itemId, string name, uint minBid, uint buyoutPrice, uint auctionEndTime);
    event HighestBidIncreased(uint itemId, address bidder, uint amount);
    event AuctionEnded(uint itemId, address winner, uint amount);
    event ItemBoughtOut(uint itemId, address buyer, uint amount);


    // Assume these image URLs have been fetched off-chain.
    // Replace the array values below with the URLs you obtained from Pixabay.
    string[10] imageUrls = [
        "https://th.bing.com/th/id/OIP.tKNQhH0mW7oF0wr0JLjFYwHaFE?w=222&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
        "https://multiwood.com.pk/cdn/shop/products/Picsart_22-10-23_03-53-33-812_1000x1000.jpg?v=1666479726",
        "https://www.swordsantiqueweapons.com/images/s2331b.jpg",
        "https://www.hemswell-antiques.com/uploads/media/news/0001/95/thumb_94739_news_wide.jpeg",
        "https://www.007.com/wp-content/uploads/2022/08/LCC-LS.jpg",
        "https://unsplash.com/photos/brown-grains-on-selective-focus-photography-w-iVGVdZvt4",
        "https://i.pcmag.com/imagery/lineupitems/06sRck1AimbfOxWwRYvEBqX.fit_lim.size_1050x578.v1569508748.jpg"
    ];

    constructor() {
        for (uint i = 0; i < 7; i++) {
            items.push(
                Item({
                    id: i,
                    seller: payable(msg.sender),
                    name: string(abi.encodePacked("Item ", uintToString(i))),
                    imageUrl: imageUrls[i],
                    minBid: 1 ether * (i + 1),
                    buyoutPrice: 5 ether * (i + 1),
                    auctionEndTime: block.timestamp + (i + 1) * 1 days,
                    highestBidder: address(0),
                    highestBid: 0,
                    ended: false
                })
            );
        }
    }

    // Helper function: converts uint to string
    function uintToString(uint v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint j = v;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (v != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + v % 10);
            bstr[k] = bytes1(temp);
            v /= 10;
        }
        return string(bstr);
    }
    function registerUser(string memory _username) public {
        require(!registered[msg.sender], "User already registered.");
        users[msg.sender] = User(_username, msg.sender);
        registered[msg.sender] = true;
        emit UserRegistered(msg.sender, _username);
    }

    function getUser(address _userAddress) public view returns (User memory) {
        require(registered[_userAddress], "User not registered.");
        return users[_userAddress];
    }

    function addItem(string memory name, string memory imageUrl, uint minBid, uint buyoutPrice, uint biddingTime) public {
        uint auctionEndTime = block.timestamp + biddingTime;
        items.push(Item({
            id: items.length,
            seller: payable(msg.sender),
            name: name,
            imageUrl: imageUrl,
            minBid: minBid,
            buyoutPrice: buyoutPrice,
            auctionEndTime: auctionEndTime,
            highestBidder: address(0),
            highestBid: 0,
            ended: false
        }));
        emit AuctionCreated(items.length - 1, name, minBid, buyoutPrice, auctionEndTime);
    }

    function bid(uint itemId) public payable {
        require(itemId < items.length, "Invalid Item ID");
        Item storage item = items[itemId];
        require(!item.ended, "Auction already ended");
        require(block.timestamp <= item.auctionEndTime, "Auction already ended");
        require(item.seller != msg.sender, "You cannot bid on your own auction");
        require(msg.value >= item.minBid, "Bid must be greater than or equal to minimum bid");
        require(msg.value > item.highestBid, "There already is a higher bid");
        require(msg.value < item.buyoutPrice, "Bid cannot be higher than buyout");

        // Refund the previous highest bidder automatically
        if (item.highestBidder != address(0)) {
            (bool success, ) = item.highestBidder.call{value: item.highestBid}("");
            require(success, "Refund to previous highest bidder failed");
        }

        // Update the highest bidder and highest bid
        item.highestBidder = payable(msg.sender);
        item.highestBid = msg.value;

        emit HighestBidIncreased(itemId, msg.sender, msg.value);
    }

    function buyout(uint itemId) public payable {
        require(itemId < items.length, "Invalid Item ID");
        Item storage item = items[itemId];
        require(!items[itemId].ended, "Auction already ended.");
        require(msg.value == item.buyoutPrice, "Buyout price not met.");

        item.ended = true;

        if (item.highestBidder != address(0)) {
            (bool success, ) = item.highestBidder.call{value: item.highestBid}("");
            require(success, "Refund to previous highest bidder failed");
        }

        item.seller.transfer(msg.value);
        
        emit ItemBoughtOut(itemId, msg.sender, msg.value);
    }

    function endAuction(uint itemId) internal {
        Item storage item = items[itemId];
        require(!item.ended, "Auction end has already been called");
        require(block.timestamp >= item.auctionEndTime, "Auction not yet ended");

        item.ended = true;

        // Transfer the highest bid amount to the seller
        item.seller.transfer(item.highestBid);

        emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
    }

    function manualEndAuction(uint itemId) public {
        require(itemId < items.length, "Invalid Item ID");
        Item storage item = items[itemId];
        require(msg.sender == item.seller, "Only the seller can end this auction");
        require(!item.ended, "Auction already ended");

        endAuction(itemId);
    }

    function itemsCount() public view returns (uint) {
        return items.length;
    }

    // Retrieve all user items
    function getAllUserItems() public view returns (Item[] memory) {
        require(registered[msg.sender], "User not registered.");

        // Count the user's items
        uint count = 0;
        for (uint index = 0; index < items.length; index++) {
            if (items[index].seller == msg.sender) {
                count++;
            }
        }

        // Allocate a memory array for the user's items
        Item[] memory list = new Item[](count);

        uint counter = 0;
        for (uint index = 0; index < items.length; index++) {
            if (items[index].seller == msg.sender) {
                list[counter] = items[index];
                counter++;
            }
        }

        return list;
    }
}