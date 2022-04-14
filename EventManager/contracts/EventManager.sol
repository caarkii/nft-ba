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
    // These are changable for each event
    uint64 public maxTicket = 5;
    uint256 public ticketPrice = 100;
    uint public ticketCount = 1;
    uint64 public transferFee = 10;
    address payable withdrawalAddress = payable(0x910DCE3971F71Ee82785FF86B47CaB938eBB9E68);
    


    constructor() ERC721("EventManager", "EM") {
    	//TokenID startet bei 1 und nicht bei 0
    	_tokenIdCounter.increment();
    }

    receive() external payable {
        // Receive() must be provided that the contract can receive ether
    }

    struct EventTicket {
        uint256 ticketPrice;
        bool availableForResell;
        address payable seller;
        address payable owner;
    }
    EventTicket[] eventticket;

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        require((maxTicket > tokenId),"There are no tickets left");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        EventTicket memory _eventticket = EventTicket({
            ticketPrice: ticketPrice,
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

    // Getter
    function getTicket(uint256 _id) 
        external 
        view 
        returns (uint256 price, bool availableForResell, address seller, address owner)
    {
        price = uint256(eventticket[_id - 1].ticketPrice);
        availableForResell = bool(eventticket[_id - 1].availableForResell);
        seller = address(eventticket[_id - 1].seller);
        owner = address(eventticket[_id - 1].owner);
    }

    function getMoney(address _ad) 
        external 
        view 
        returns (uint256 balance)
    {
        balance = uint256(_ad.balance);
    }

    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }
    // Setter

    function setForResale(uint256 _id, uint256 _newPrice) 
        external  
    {
        //require((ownerOf(_id) == msg.sender),"You do not have the permission to change that ticket");
        transferFrom(msg.sender, address(this), _id);
        eventticket[_id - 1].availableForResell = true;
        eventticket[_id - 1].ticketPrice = _newPrice;
        eventticket[_id - 1].seller = payable(msg.sender);
        eventticket[_id - 1].owner = payable(address(this));
    }

    function buyTicketFromAttendee(uint256 _ticketId) 
    external
    payable
    {
        require(eventticket[_ticketId - 1].availableForResell = true,"ticket not for sale");
        uint256 _priceToPay = eventticket[_ticketId - 1].ticketPrice;
        //address owner = ownerOf(_ticketId);
        require((msg.value >= _priceToPay + transferFee),"not enough money");

        address seller = eventticket[_ticketId - 1].seller;
        address owner = eventticket[_ticketId - 1].owner;
        
        payable(owner).transfer(transferFee);
        payable(seller).transfer(msg.value - transferFee);
        _transfer(address(this), msg.sender, _ticketId);
        //payable(seller).transfer(_priceToPay);
        
        eventticket[_ticketId - 1].availableForResell = false;
         
    }

    function sendMoney() public payable {

address payable seller = payable(address(this));
//address payable seller = payable(0x9199D9323b25BA171De6b9189201Bb322Ba12274);

address payable sellerino = payable(0x910DCE3971F71Ee82785FF86B47CaB938eBB9E68);
sellerino.transfer(transferFee);
  seller.transfer(msg.value - transferFee);
}

}