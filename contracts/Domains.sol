// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";
import { StringUtils } from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

contract Domains is ERC721URIStorage {
    //keeps track of tokenIDs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    //TLD
    string public tld;

    //SVG for NFT image
    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M57.834,0C25.895,0,0,25.894,0,57.834c0,31.939,25.895,57.834,57.834,57.834c31.942,0,57.834-25.895,57.834-57.834 C115.668,25.894,89.775,0,57.834,0z M23.827,66.199c-4.618,0-8.363-3.746-8.363-8.364c0-4.62,3.745-8.364,8.363-8.364 c4.621,0,8.365,3.744,8.365,8.364C32.192,62.453,28.448,66.199,23.827,66.199z M41.957,92.755l-1.245-5.869l33-7l1.244,5.869 L41.957,92.755z M91.84,66.199c-4.619,0-8.363-3.746-8.363-8.364c0-4.62,3.744-8.364,8.363-8.364s8.365,3.744,8.365,8.364 C100.205,62.453,96.459,66.199,91.84,66.199z" fill="#000"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#36454F"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#36454F" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    address payable public owner;

  //Mapping data type to store names
  mapping(string => address) public domains;

  //Mapping to store values
  mapping(string => string) public records;

  //Mapping to store registered domains
  mapping (uint => string) public names;

  error Unauthorized();
  error AlreadyRegistered();
  error InvalidName(string name);

  //Makes contract payable
  constructor(string memory _tld) payable ERC721("rekt Name Service", "rektNS") {
      owner = payable(msg.sender);
      tld = _tld;
      console.log("%s Name Service deployed", _tld);
  }

  //Gives price of domain based on length
  function price(string calldata name) public pure returns(uint) {
      uint len = StringUtils.strlen(name);
      require(len > 0);
      if (len == 3) {
          return 5 * 10**17; //0.5 MATIC
      } else if (len == 4) {
          return 3 * 10**17;
      } else {
          return 1 * 10**17;
      }
  }

  function valid(string calldata name) public pure returns(bool) {
      return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 12;
  }

  //Register functiont hat adds name to mapping
  function register(string calldata name) public payable {
      //check to make sure name hasn't been registered yet
      if (domains[name] != address(0)) revert AlreadyRegistered();
      if (!valid(name)) revert InvalidName(name);
      uint _price = price(name);
      //Check to make sure payment was adequate
      require(msg.value >= _price, "Not enough MATIC paid.");

      //Combine name with TLD
      string memory _name = string(abi.encodePacked(name, ".", tld));
      //Create SVG using name
      string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));

      uint256 newRecordId = _tokenIds.current();
      uint256 length = StringUtils.strlen(name);
      string memory strLen = Strings.toString(length);

      console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

      //Creating JSON of metadata for NFT by combining strings and encoding as base64
      string memory json = Base64.encode(
          bytes(
              string(
                  abi.encodePacked(
                      '{"name": "',
                      _name,
                      '", "description": "A domain of the rekt Name Service", "image": "data:image/svg+xml;base64,',
                      Base64.encode(bytes(finalSvg)),
                      '", "length": "',
                      strLen,
                      '"}'
                  )
              )
          )
      );

      string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,",json));

      console.log("\n------------------------------");
      console.log("Final tokenURI: ", finalTokenUri);
      console.log("-------------------------------\n");

      _safeMint(msg.sender, newRecordId);
      _setTokenURI(newRecordId, finalTokenUri);
      domains[name] = msg.sender;
      console.log("%s has registered a domain!", msg.sender);
    
      names[newRecordId] = name;
      _tokenIds.increment();
  }

  //Function to get domain owners' address
  function getAddress(string calldata name) public view returns (address) {
      return domains[name];
  }

  function setRecord(string calldata name, string calldata record) public {
      //check to make sure that owner is transaction sender
      if (domains[name] != msg.sender) revert Unauthorized();
      records[name] = record;
  }

  function getRecord(string calldata name) public view returns (string memory) {
      return records[name];
  }

  function getAllNames() public view returns (string[] memory) {
      console.log("Getting all names from contract...");
      string[] memory allNames = new string[](_tokenIds.current());
      for (uint i = 0; i < _tokenIds.current(); i++) {
          allNames[i] = names[i];
          console.log("Name for token %d is %s", i, allNames[i]);
      }
      return allNames;
  }
  
  modifier onlyOwner() {
      require(isOwner());
      _;
  }

  function isOwner() public view returns (bool) {
      return msg.sender == owner;
  }

  function withdraw() public onlyOwner {
      uint amount = address(this).balance;
      (bool success, ) = msg.sender.call{value: amount}("");
      require(success, "Failed to withdraw MATIC :(");
  }
 
}