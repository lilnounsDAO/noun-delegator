// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

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

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

pragma solidity ^0.8.6;

interface INounsTokenLike is IERC721 {
  function balanceOf(address account) external view returns (uint256);

  function getCurrentVotes(address account) external view returns (uint96);

  function delegates(address delegator) external view returns (address);

  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

  function totalSupply() external view returns (uint256);
}
