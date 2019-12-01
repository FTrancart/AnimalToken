pragma solidity ^0.5.0;

import "./ERC721.sol";

contract DogToken {

    mapping (uint256 => Animal) public listAnimals;
    mapping(uint256 => Auction) public listAuctions;
    mapping (address => uint256) public balances;
    mapping(address => bool) public breeder;
    
    uint256 nbAuctions;
    uint256 nbAnimals;

    ERC721 ercContract;

    constructor (ERC721 _contract) public {
        ercContract  = _contract;
    }

    modifier onlyBreeder() {
        require(breeder[msg.sender], "Owner is not a registered breeder");
        _;
    }
    modifier onlyOwner(address owner) {
        require(owner == msg.sender, "Sender is not the owner of the animal");
        _;
    }
    modifier onlyOneOfOwners(address owner, address owner2) {
        require((owner == msg.sender) || (msg.sender == owner2), "Sender is not one of the owners");
        _;
    }

    struct Auction 
    {
        bool open;
        uint256 animalId;
        uint256 currentPrice;
        uint256 duration;
        uint256 startDate;
        address owner;
        address lastBuyer;
    }

    struct Animal 
    {
        address owner;
        bool fight;
        bool breed;
        uint256 salePrice;
    }

    function balanceOf(address a) public view returns(uint256) {
        return balances[a];
    }

    function ownerOf(uint256 tokenId) public view returns(address) {
        return listAnimals[tokenId].owner;
    }

    /*White list breeders*/
    function registerBreeder() public {
        breeder[msg.sender] = true;
    }

    /*Mint free 'eth' tokens*/
    function creditBalance(uint256 amount, address beneficiary) public {
        balances[beneficiary] += amount;
    }

    /*Register a new dog to its owner
    Sender has to approve current contract to 
    retrieve tokens from ERC721 before calling deposit()*/
    function deposit(uint256 tokenId, address owner) public returns(bool) {
        require(listAnimals[tokenId].owner == address(0), "Token id already exists");
        ercContract.transferFrom(owner, address(this), tokenId);
        listAnimals[tokenId] = Animal(msg.sender, false, false, 0);
        return true;
    }


    function withdrawal(uint256 tokenA, uint256 tokenB) public onlyOneOfOwners(listAnimals[tokenA].owner, listAnimals[tokenB].owner) {
        delete listAnimals[tokenA];
        ercContract.burn(tokenA);
    }

    function putToSale(uint256 tokenId, uint256 _salePrice) public onlyOwner(listAnimals[tokenId].owner) {
        listAnimals[tokenId].salePrice = _salePrice;
    }

    function buyFixedPrice(uint256 tokenId) public {
        require(balances[msg.sender] >= listAnimals[tokenId].salePrice, "Buyer has not enough eth on balance");
        require(listAnimals[tokenId].salePrice != 0, "Animal is not on sale");
        balances[msg.sender] -= listAnimals[tokenId].salePrice;
        balances[listAnimals[tokenId].owner] += listAnimals[tokenId].salePrice;
        listAnimals[tokenId] = Animal(msg.sender, false, false, 0);
    }

    function findFight(uint256 tokenId) public onlyOwner(listAnimals[tokenId].owner) {
        listAnimals[tokenId].fight = true;
    }

    function fight(uint256 tokenA, uint256 tokenB, uint256 bet) public onlyOneOfOwners(listAnimals[tokenA].owner, listAnimals[tokenB].owner) returns(uint256) {
        require(balances[listAnimals[tokenA].owner] >= bet && balances[listAnimals[tokenB].owner] >= bet, "One of the owners has not enough credit on balance");
        require(listAnimals[tokenA].fight == true && listAnimals[tokenB].fight == true, "The two owners have not delcared the animals can fight");
        
        uint256 survivor;
        uint256 dead;
        if(uint8(uint256(keccak256(abi.encodePacked(block.timestamp)))%251) < 125) {
            survivor = tokenB;
            dead = tokenA;
        }
        else {
            survivor = tokenA;
            dead = tokenB;
        }
        
        listAnimals[survivor].fight = false;
        balances[listAnimals[dead].owner] -= bet;
        balances[listAnimals[survivor].owner] += bet;
        withdrawal(dead, survivor);
        return survivor;
    }

    function wantsToBreed(uint256 tokenId) public onlyBreeder() onlyOwner(listAnimals[tokenId].owner) {
        listAnimals[tokenId].breed = true;
    }

    function breed(uint256 tokenA, uint256 tokenB, address newOwner) public onlyBreeder() onlyOneOfOwners(listAnimals[tokenA].owner, listAnimals[tokenB].owner) {
       require(listAnimals[tokenA].breed == true && listAnimals[tokenB].breed == true, "both owners do not agree to breed");
       uint256 newId = ercContract.mintNew(tokenA, tokenB);
       
       require(listAnimals[newId].owner == address(0), "token already exists");
       listAnimals[newId] = Animal(newOwner, false, false, 0);
       listAnimals[tokenA].breed = false;
       listAnimals[tokenB].breed = false;
   }
   
   function createAuction(uint256 tokenId, uint startPrice, uint256 nbDays) public onlyOwner(listAnimals[tokenId].owner) {
    listAuctions[nbAuctions] = Auction(true, tokenId, startPrice, nbDays * 1 days, now, msg.sender, address(0));
    nbAuctions++;
}

function bidOnAuction(uint256 auctionId, uint256 bid) public {
    require((listAuctions[auctionId].duration + listAuctions[auctionId].startDate) > now, "Auction is closed");
    require(balances[msg.sender] >= bid, "Sender has not enough credit on balance");
    require(bid > listAuctions[auctionId].currentPrice, "Bid is lower than current auction price");
    balances[msg.sender] -= bid;
    balances[listAuctions[auctionId].owner] += (bid - listAuctions[auctionId].currentPrice);
    balances[listAuctions[auctionId].lastBuyer] += listAuctions[auctionId].currentPrice;
    listAuctions[auctionId] = Auction(true, listAuctions[auctionId].animalId, bid, listAuctions[auctionId].duration, listAuctions[auctionId].startDate, listAuctions[auctionId].owner, msg.sender);
}

function claimAuction(uint256 auctionId) public {
    require(msg.sender == listAuctions[auctionId].lastBuyer, "Sender is not the highest bider");
    require((listAuctions[auctionId].duration + listAuctions[auctionId].startDate) < now, "Auction is not closed");
    listAnimals[listAuctions[auctionId].animalId] = Animal(msg.sender, false, false, 0);
}
}
