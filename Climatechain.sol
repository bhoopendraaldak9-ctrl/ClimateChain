// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Climate Chain - Carbon Credit Trading & Environmental Impact Tracking
 * @dev A decentralized platform for carbon credit trading and environmental project verification
 * @custom:dev-run-script npx hardhat run scripts/deploy.js --network localhost
 */
contract Project {
    
    // State variables
    address public owner;
    uint256 public totalCarbonCredits;
    uint256 public totalProjectsRegistered;
    uint256 public nextProjectId;
    
    // Structs
    struct CarbonCredit {
        uint256 amount;
        uint256 price;
        address seller;
        bool isActive;
        uint256 timestamp;
    }
    
    struct EnvironmentalProject {
        uint256 id;
        string name;
        string description;
        address owner;
        uint256 carbonCreditsGenerated;
        bool isVerified;
        uint256 creationTime;
    }
    
    // Mappings
    mapping(address => uint256) public carbonCreditBalance;
    mapping(uint256 => CarbonCredit) public carbonCreditListings;
    mapping(uint256 => EnvironmentalProject) public environmentalProjects;
    mapping(address => uint256[]) public userProjects;
    
    // Events
    event CarbonCreditListed(uint256 indexed listingId, address indexed seller, uint256 amount, uint256 price);
    event CarbonCreditPurchased(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 amount);
    event ProjectRegistered(uint256 indexed projectId, address indexed owner, string name);
    event ProjectVerified(uint256 indexed projectId, uint256 creditsAwarded);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier validProject(uint256 _projectId) {
        require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        nextProjectId = 1;
    }
    
    /**
     * @dev Core Function 1: Register Environmental Project
     * @param _name Project name
     * @param _description Project description
     * @return projectId The ID of the newly registered project
     */
    function registerEnvironmentalProject(
        string memory _name, 
        string memory _description
    ) public returns (uint256 projectId) {
        require(bytes(_name).length > 0, "Project name cannot be empty");
        require(bytes(_description).length > 0, "Project description cannot be empty");
        
        projectId = nextProjectId;
        
        environmentalProjects[projectId] = EnvironmentalProject({
            id: projectId,
            name: _name,
            description: _description,
            owner: msg.sender,
            carbonCreditsGenerated: 0,
            isVerified: false,
            creationTime: block.timestamp
        });
        
        userProjects[msg.sender].push(projectId);
        totalProjectsRegistered++;
        nextProjectId++;
        
        emit ProjectRegistered(projectId, msg.sender, _name);
        return projectId;
    }
    
    /**
     * @dev Core Function 2: Trade Carbon Credits
     * @param _listingId The ID of the carbon credit listing to purchase
     */
    function tradeCarbonCredits(uint256 _listingId) public payable {
        CarbonCredit storage listing = carbonCreditListings[_listingId];
        
        require(listing.isActive, "Listing is not active");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller, "Cannot buy your own credits");
        
        // Transfer carbon credits to buyer
        carbonCreditBalance[msg.sender] += listing.amount;
        carbonCreditBalance[listing.seller] -= listing.amount;
        
        // Transfer payment to seller
        payable(listing.seller).transfer(listing.price);
        
        // Return excess payment if any
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
        
        // Mark listing as inactive
        listing.isActive = false;
        
        emit CarbonCreditPurchased(_listingId, msg.sender, listing.seller, listing.amount);
    }
    
    /**
     * @dev Core Function 3: Verify and Award Carbon Credits
     * @param _projectId The ID of the project to verify
     * @param _creditsToAward Amount of carbon credits to award
     */
    function verifyAndAwardCredits(uint256 _projectId, uint256 _creditsToAward) 
        public 
        onlyOwner 
        validProject(_projectId) 
    {
        require(_creditsToAward > 0, "Credits to award must be greater than 0");
        
        EnvironmentalProject storage project = environmentalProjects[_projectId];
        require(!project.isVerified, "Project already verified");
        
        // Mark project as verified
        project.isVerified = true;
        project.carbonCreditsGenerated = _creditsToAward;
        
        // Award credits to project owner
        carbonCreditBalance[project.owner] += _creditsToAward;
        totalCarbonCredits += _creditsToAward;
        
        emit ProjectVerified(_projectId, _creditsToAward);
    }
    
    // Additional utility functions
    
    /**
     * @dev List carbon credits for sale
     * @param _amount Amount of credits to sell
     * @param _price Price in wei for the entire amount
     * @return listingId The ID of the created listing
     */
    function listCarbonCredits(uint256 _amount, uint256 _price) public returns (uint256 listingId) {
        require(carbonCreditBalance[msg.sender] >= _amount, "Insufficient carbon credits");
        require(_price > 0, "Price must be greater than 0");
        
        listingId = block.timestamp; // Simple listing ID based on timestamp
        
        carbonCreditListings[listingId] = CarbonCredit({
            amount: _amount,
            price: _price,
            seller: msg.sender,
            isActive: true,
            timestamp: block.timestamp
        });
        
        emit CarbonCreditListed(listingId, msg.sender, _amount, _price);
        return listingId;
    }
    
    /**
     * @dev Get project details
     * @param _projectId The ID of the project
     * @return project The environmental project details
     */
    function getProjectDetails(uint256 _projectId) 
        public 
        view 
        validProject(_projectId) 
        returns (EnvironmentalProject memory project) 
    {
        return environmentalProjects[_projectId];
    }
    
    /**
     * @dev Get user's projects
     * @param _user The address of the user
     * @return projectIds Array of project IDs owned by the user
     */
    function getUserProjects(address _user) public view returns (uint256[] memory projectIds) {
        return userProjects[_user];
    }
    
    /**
     * @dev Get contract statistics
     * @return totalProjects Total number of registered projects
     * @return totalCredits Total carbon credits in circulation
     * @return contractBalance Contract's ETH balance
     */
    function getContractStats() public view returns (uint256 totalProjects, uint256 totalCredits, uint256 contractBalance) {
        return (totalProjectsRegistered, totalCarbonCredits, address(this).balance);
    }
}