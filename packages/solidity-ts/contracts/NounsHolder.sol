// SPDX-License-Identifier: GPL-3.0

/// @title Nouns holder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

/**
 * TLDR: A contract built to circumvent nouns' 1 prop per wallet rule by
 * allowing for a permissioned wallet/contract to intermediate nouns dao actions(voting, proposing, signing) between the nouns held by this contract and Nouns DAO.
 *
 * REQUIREMENTS
 * Accepts nouns votes via transfer or delegation
 * Only LilNounsDAO Executor can delegate permissions to wallet/contract
 * Only LilNounsDAO Executor can transfer nouns back to treasury
 *
 * specified wallet/contract can propose to nouns dao using nouns delegated/held in contract
 * specified wallet/contract can vote on nouns dao proposals using nouns delegated/held in contract
 * specified wallet/contract can cancel nouns dao proposals using nouns delegated/held in contract
 *
 * DAOs should be able to deploy and allocate nouns to a NounsHolder contract in one proposal
 * NounsHolder contracts should be upgradable
 *
 *? Question: How will this scale to work with liquid delegation and/or federation
 *? Question: Will this affect our ability to claim drops like nounsvision glasses
 *? Question: How could this contract utilise nounsconnect.wtf?
 *? Question: Should we give each NounsHolder contract a "delegateSpokesperson" param that lets lil nouns dao assign a 'nouner-private' discord member to?
 */

pragma solidity ^0.8.6;

import { INounsHolder } from "./interfaces/INounsHolder.sol";
import { INounsTokenLike } from "./interfaces/INounsTokenLike.sol";
import { INounsDAOLogicLike } from "./interfaces/INounsDAOLogicLike.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract NounsHolder is Ownable, INounsHolder {
  // The Lil Nouns DAO address (Executor)
  address public lilnounsDAO;

  // LilNounsToken contract address
  address public lilnounsToken;

  // The wallet or contract designated to propose, vote, sign on behalf of all nouns held/delegated to this contract
  address public delegate;

  // NounsToken contract address
  INounsTokenLike public nounsToken;

  // nounsDAOProxy contract address (to call NounsDAOLogicV2 implementation address)
  INounsDAOLogicLike public nounsDao;

  /**
   * @notice Require that the sender is the Lil Nouns DAO.
   */
  modifier onlyLilNounsDAO() {
    require(msg.sender == lilnounsDAO, "Sender is not the Lil Nouns DAO");
    _;
  }

  /**
   * @notice Require that the sender is either the delegated wallet/contract or Lil Nouns DAO.
   */
  modifier onlyDelegateOrLilnounsDAO() {
    require(msg.sender == delegate || msg.sender == lilnounsDAO, "Sender is not the delegate or Lil Nouns DAO");
    _;
  }

  /**
   * @notice Require that the contract has enough nouns to propose.
   */
  modifier hasEnoughToNounsPropose() {
    uint256 proposalThreshold = bps2Uint(nounsDao.proposalThresholdBPS(), nounsToken.totalSupply());

    require(nounsToken.getPriorVotes(msg.sender, block.number - 1) > proposalThreshold, "Contract does not have enough nouns to propose");
    _;
  }

  /**
   * @notice Require that the contract has enough nouns to vote.
   */
  modifier hasEnoughNounsToVote() {
    require(nounsToken.getPriorVotes(msg.sender, block.number - 1) >= 1, "Contract does not have enough nouns to vote");
    _;
  }

  constructor(
    address _lilnounsDAO,
    address _lilnounsToken,
    address _delegate,
    address _nounsToken,
    address _nounsDAOLogic
  ) {
    lilnounsDAO = _lilnounsDAO;
    lilnounsToken = _lilnounsToken;
    delegate = _delegate;

    nounsToken = INounsTokenLike(_nounsToken);
    nounsDao = INounsDAOLogicLike(_nounsDAOLogic);
  }

  /**
   * @notice Set Lil Nouns DAO's Executor address.
   * @dev Only callable by lilnounsDAO.
   */
  function setLilNounsDAO(address _lilnounsDAO, address _lilnounsToken) external override onlyLilNounsDAO {
    lilnounsDAO = _lilnounsDAO;
    lilnounsToken = _lilnounsToken;
    emit LilNounsDAOUpdated(_lilnounsDAO);
  }

  /**
   * @notice Set the delegate.
   * @dev Only callable by lilnounsDAO.
   */
  function setDelegate(address _delegate) external override onlyLilNounsDAO {
    delegate = _delegate;
    emit DelegateUpdated(_delegate);
  }

  /**
   * @notice Set nounsDaoLogic.
   * @dev Only callable by lilnounsDAO.
   */
  function setNounsDAOLogic(INounsDAOLogicLike _nounsDAOLogic) external override onlyLilNounsDAO {
    nounsDao = _nounsDAOLogic;
    emit NounsDAOLogicUpdated(_nounsDAOLogic);
  }

  /**
   * @notice Set nouns DAO's token address.
   * @dev Only callable by lilnounsDAO.
   */
  function setNounsDAOToken(INounsTokenLike _nounsToken) external override onlyLilNounsDAO {
    nounsToken = _nounsToken;
    emit NounsDAOTokenUpdated(_nounsToken);
  }

  /**
   * @notice Reports the number of nouns dao votes this contract owns and has been externally delegated.
   * @dev Conforms to the expected ERC-721 function signature `balanceOf(address)` used by token-gate registries
   */
  function nounTokensHeldOrDelegated() public view returns (uint256) {
    uint256 votes = uint256(nounsToken.getCurrentVotes(address(this)));
    return votes;
  }

  /**
   * @notice Batch transfer all nouns held by contract to Lil Nouns Treasury
   * @dev Only callable by lilnounsDAO.
   */
  function transferNouns(address to, uint256[] calldata tokenIds) external override onlyLilNounsDAO {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(nounsToken.ownerOf(tokenIds[i]) == address(this), "This contract does not own this Noun");
      nounsToken.transferFrom(address(this), to, tokenIds[i]);
      emit nounTransferred(to, tokenIds[i]);
    }
  }

  /**
   * @notice Allows delegate to propose in nouns DAO using votes held by this contract.
   * @dev Only callable by Lil Nouns DAO and the lilnounsDAO assigned delegate wallet/contract.
   */
  function proposeWithNouns(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) external override onlyDelegateOrLilnounsDAO hasEnoughToNounsPropose returns (uint256) {
    //TODO: make sure this call returns the exact response you'd get from calling propose() in nouns
    uint256 propId = nounsDao.propose(targets, values, signatures, calldatas, description);
    return propId;
  }

  /**
   * @notice Allows delegate to vote in nouns DAO using votes held by this contract.
   * @dev Only callable if contract has enough nouns to vote.
   */
  function voteWithNouns(uint256 proposalId, uint8 support) external override onlyDelegateOrLilnounsDAO hasEnoughNounsToVote {
    //TODO: check if possible to cast vote via castRefundableVote/WithReason
    nounsDao.castVote(proposalId, support);
  }

  /**
   * @notice Allows delegate to cancel proposed props in nouns DAO using votes held by this contract.
   * @dev Only callable by Lil Nouns DAO and the lilnounsDAO assigned delegate wallet/contract.
   */
  function cancelProposalWithNouns(uint256 proposalId) external override onlyDelegateOrLilnounsDAO {
    nounsDao.cancel(proposalId);
  }

  /**
   * @notice Allows delegate to sign on behalf of nouns held/delegated to this contract
   * @dev Only callable by Lil Nouns DAO and the lilnounsDAO assigned delegate wallet/contract.
   */
  function signWithNouns(
    bytes32 messageHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external view onlyDelegateOrLilnounsDAO returns (bool) {
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    return ecrecover(prefixedHash, v, r, s) == delegate;
  }

  function bps2Uint(uint256 bps, uint256 number) internal pure returns (uint256) {
    return (number * bps) / 10000;
  }
}
