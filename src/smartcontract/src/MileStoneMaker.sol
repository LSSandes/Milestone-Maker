// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MileStoneMaker is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    uint256 private _learningPathIds;

    struct LearningPath {
        uint256 id;
        string ipfsHash;
        bool[] milestones;
        bool completed;
        bool achievementMinted;
    }

    mapping(address => mapping(uint256 => LearningPath))
        public userLearningPaths;
    mapping(address => uint256[]) public userLearningPathIds;

    address public aiAgent;

    event LearningPathCreated(
        address user,
        uint256 learningPathId,
        string ipfsHash
    );
    event MilestoneCompleted(address user, uint256 learningPathId);
    event AchievementMinted(
        address user,
        uint256 learningPathId,
        uint256 tokenId
    );

    constructor() ERC721("MileStoneMaker", "MM") Ownable(msg.sender) {}

    modifier onlyAIAgent() {
        require(msg.sender == aiAgent, "Caller is not the AI Agent");
        _;
    }

    function setAIAgent(address _newAIAgent) public onlyOwner {
        aiAgent = _newAIAgent;
    }

    function createLearningPath(
        address _user,
        string memory _ipfsHash,
        uint256 _milestoneCount
    ) public onlyAIAgent returns (uint256) {
        require(_milestoneCount > 0, "Milestone count must be greater than 0");

        _learningPathIds++;
        uint256 newLearningPathId = _learningPathIds;

        bool[] memory completedMilestones = new bool[](_milestoneCount);
        userLearningPaths[_user][newLearningPathId] = LearningPath(
            newLearningPathId,
            _ipfsHash,
            completedMilestones,
            false,
            false
        );
        userLearningPathIds[_user].push(newLearningPathId);

        emit LearningPathCreated(_user, newLearningPathId, _ipfsHash);

        return newLearningPathId;
    }

    function updateMilestones(
        address _user,
        uint256 _learningPathId,
        bool[] memory _milestones
    ) public onlyAIAgent {
        require(
            userLearningPaths[_user][_learningPathId].id != 0,
            "Learning path does not exist"
        );
        require(
            _milestones.length ==
                userLearningPaths[_user][_learningPathId].milestones.length,
            "Milestone count mismatch"
        );
        LearningPath storage path = userLearningPaths[_user][_learningPathId];
        path.milestones = _milestones;
    }

    function completeMilestone(
        address _user,
        uint256 _learningPathId
    ) public onlyAIAgent {
        LearningPath storage path = userLearningPaths[_user][_learningPathId];
        require(path.id != 0, "Learning path does not exist");
        require(!path.completed, "Learning path already completed");

        emit MilestoneCompleted(_user, _learningPathId);

        bool allCompleted = true;
        for (uint256 i = 0; i < path.milestones.length; i++) {
            if (!path.milestones[i]) {
                allCompleted = false;
                break;
            }
        }

        if (allCompleted) {
            path.completed = true;
        }
    }

    function mintAchievement(
        address _user,
        uint256 _learningPathId,
        string memory _tokenURI
    ) public {
        require(msg.sender == _user, "Only owner can mint the NFT");
        LearningPath storage path = userLearningPaths[_user][_learningPathId];
        require(path.completed, "Learning path is not completed");
        require(
            !path.achievementMinted,
            "Achievement already minted for this learning path"
        );

        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _safeMint(_user, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        path.achievementMinted = true;

        emit AchievementMinted(_user, _learningPathId, newItemId);
    }

    function isEligibleForNFT(
        address _user,
        uint256 _learningPathId
    ) public view returns (bool) {
        return userLearningPaths[_user][_learningPathId].completed;
    }

    function getLearningPath(
        address _user,
        uint256 _learningPathId
    ) public view returns (string memory, bool[] memory, bool, bool) {
        LearningPath memory path = userLearningPaths[_user][_learningPathId];
        return (
            path.ipfsHash,
            path.milestones,
            path.completed,
            path.achievementMinted
        );
    }

    function getUserLearningPathIds(
        address _user
    ) public view returns (uint256[] memory) {
        return userLearningPathIds[_user];
    }

    function getMilestones(
        address _user,
        uint256 _learningPathId
    ) public view returns (bool[] memory) {
        LearningPath storage path = userLearningPaths[_user][_learningPathId];
        return path.milestones;
    }
}