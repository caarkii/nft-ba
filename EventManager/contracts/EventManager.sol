// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/utils/Counters.sol";

contract EventManager is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Values which are set at the deployment
    // These can be configured for each event
    uint64 public maxTicket = 5;
    uint256 public ticketPrice = 100;
    uint256 public maxTicketPrice = 150;
    uint public ticketCount = 1;
    uint64 public transferFee = 10;
    uint64 public maxResellTimes = 3;

    constructor() ERC721("EventManager", "EM") {
    	//TokenID startet bei 1 und nicht bei 0
    	_tokenIdCounter.increment();
    }

    receive() external payable {
        // This function must be provided to be able to receive funds
    }

    struct EventTicket {
        uint256 ticketPrice;
        uint256 numberOfResell;
        bool availableForResell;
        address payable seller;
        address payable owner;
    }
    EventTicket[] eventticket;

    //To buy a ticket from the primary market
    function safeMint(address to, string memory uri) public payable onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        require((maxTicket > tokenId),"There are no tickets left");
        uint256 _priceToPay = ticketPrice;
        require((msg.value >= _priceToPay),"There is not enough funds");

        address payable owner = payable(address(this));
        owner.transfer(_priceToPay);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        EventTicket memory _eventticket = EventTicket({
            ticketPrice: ticketPrice,
            numberOfResell: 0,
            availableForResell: bool(false),
            seller: payable(msg.sender),
            owner: payable(address(this))
        });
        eventticket.push(_eventticket);
        ticketCount += 1;
    }
    

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Getter functions
    function getTicket(uint256 _id) 
        external 
        view 
        returns (uint256 price, uint64 resellTimes, bool availableForResell, address seller, address owner)
    {
        price = uint256(eventticket[_id - 1].ticketPrice);
        resellTimes = uint64(eventticket[_id - 1].numberOfResell);
        availableForResell = bool(eventticket[_id - 1].availableForResell);
        seller = address(eventticket[_id - 1].seller);
        owner = address(eventticket[_id - 1].owner);
    }

    // Get the balance of an account
    function getMoney(address _ad) 
        external 
        view 
        returns (uint256 balance)
    {
        balance = uint256(_ad.balance);
    }

    // Get the balance of the smart-contract
    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }

    // Setting a ticket for resale
    function offerTicketOnMarket(uint256 _id, uint256 _newPrice) 
        external  
    {
        require((ownerOf(_id) == msg.sender),"No Permission to sell this tickt");
        require((maxTicketPrice > _newPrice),"New Price is exceeds maximum ticket price");
        require((eventticket[_id - 1].numberOfResell < maxResellTimes),"Maximum number of resales reached");
        transferFrom(msg.sender, address(this), _id);
        eventticket[_id - 1].availableForResell = true;
        eventticket[_id - 1].ticketPrice = _newPrice;
        eventticket[_id - 1].seller = payable(msg.sender);
        eventticket[_id - 1].owner = payable(address(this));
    }

    // Buying a ticket from the secondary market place
    function buyTicketSecondary(uint256 _id) 
    external
    payable
    {
        require(eventticket[_id - 1].availableForResell = true,"ticket not for sale");
        uint256 _priceToPay = eventticket[_id - 1].ticketPrice;
        require((msg.value >= _priceToPay + transferFee),"not enough money");

        address seller = eventticket[_id - 1].seller;
        address owner = eventticket[_id - 1].owner;
        
        payable(owner).transfer(transferFee);
        payable(seller).transfer(msg.value - transferFee);
        _transfer(address(this), msg.sender, _id);
        
        eventticket[_id - 1].availableForResell = false;
        eventticket[_id - 1].numberOfResell += 1;
         
    }

}