// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Presale is ReentrancyGuard, Ownable, Pausable {
    IERC20 public token;

    uint256 public constant TOTAL_TOKENS = 40 * 10**6 * 10**18; // 40 milyon token, 18 ondalık basamakla
    uint256 public constant TOTAL_ROUNDS = 10;
    uint256 public constant MAX_TOKENS_PER_ADDRESS = 40000 * 10**18;
    uint256 public tokensPerRound = TOTAL_TOKENS / TOTAL_ROUNDS;
    uint256 public currentRound = 1;
    uint256 public soldTokensInCurrentRound = 0;
    uint256 public startTime; // Presale başlangıç zamanı

    uint256 public tokenPriceETH = 6 * 10**12; // 1 token'in ETH cinsinden fiyatı (0.000006 ETH)
    bool public salePaused = false;

    constructor(address _tokenAddress, uint256 _startTime) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
        startTime = _startTime;
    }

    modifier tokenPriceNotZero(uint256 _tokenPriceETH) {
        require(_tokenPriceETH > 0, "Token price can not be zero");
        _;
    }

    modifier tokenAddressNotZero(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token address can not be zero");
        _;
    }
    modifier withinTokenLimit(uint256 tokensToBuy) {
        uint256 totalTokensAfterPurchase = token.balanceOf(msg.sender) + tokensToBuy;
        require(totalTokensAfterPurchase <= MAX_TOKENS_PER_ADDRESS, "Purchase exceeds maximum allowed tokens per address");
        _;
    }

    function buyTokens() public payable nonReentrant whenNotPaused withinTokenLimit(msg.value / tokenPriceETH) {
        require(block.timestamp >= startTime, "Presale has not started yet"); // Presale başlangıç kontrolü
        require(currentRound <= TOTAL_ROUNDS, "Pre-sale has ended");
        require(msg.value > 0, "You need to send some ETH");

        uint256 tokensToBuy = msg.value / tokenPriceETH; // Gönderilen ETH miktarına göre alınacak token miktarı

        require(tokensToBuy >= 1000, "Minimum purchase is 1000 tokens");
        require(token.balanceOf(address(this)) >= tokensToBuy, "Not enough tokens in the contract"); // Kontratta yeterli token olup olmadığını kontrol edin

        soldTokensInCurrentRound += tokensToBuy;
        if (soldTokensInCurrentRound >= tokensPerRound && currentRound < TOTAL_ROUNDS) {
            currentRound++;
            soldTokensInCurrentRound = 0;
        }

        token.transfer(msg.sender, tokensToBuy);
    }

    function pauseSale() external onlyOwner {
        _pause();
    }

    function resumeSale() external onlyOwner {
        _unpause();
    }

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setTokenPrice(uint256 _tokenPriceETH) external onlyOwner tokenPriceNotZero(_tokenPriceETH) {
        tokenPriceETH = _tokenPriceETH;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }
}
