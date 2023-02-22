// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsHolder

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

import { INounsDAOLogicLike } from "./INounsDAOLogicLike.sol";
import { INounsTokenLike } from "./INounsTokenLike.sol";

pragma solidity ^0.8.6;

interface INounsHolder {
  event nounTransferred(address to, uint256 tokenId);

  event LilNounsDAOUpdated(address indexed lilnounsDAO);

  event DelegateUpdated(address indexed delegate);

  event NounsDAOLogicUpdated(INounsDAOLogicLike nounsDAOLogic);

  event NounsDAOTokenUpdated(INounsTokenLike nounsToken);

  function setLilNounsDAO(address _lilnounsDAO, address _lilnounsToken) external;

  function setDelegate(address _delegate) external;

  function setNounsDAOLogic(INounsDAOLogicLike _nounsDAOLogic) external;

  function setNounsDAOToken(INounsTokenLike _nounsToken) external;

  function nounTokensHeldOrDelegated() external view returns (uint256);

  function transferNouns(address to, uint256[] calldata tokenIds) external;

  function proposeWithNouns(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) external returns (uint256);

  function voteWithNouns(uint256 proposalId, uint8 support) external;

  function cancelProposalWithNouns(uint256 proposalId) external;

  function signWithNouns(
    bytes32 messageHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external view returns (bool);
}
