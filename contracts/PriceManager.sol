// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract PriceManager {
    enum PriceType {FIXED, DECLIINING_BY_TIME}
    address public manager;
    struct DecliningPrice {
        uint128 highest; 
        uint128 lowest; 
        uint32 startTime;
        uint32 duration; 
        uint32 interval; 
    }

    mapping(uint24 => DecliningPrice) internal decliningPrices;
    mapping(uint24 => uint128) internal fixedPrices;

modifier onlyManager{
    require(msg.sender == manager, "u not owner");
    
    _;

}

    function price(PriceType priceType_, uint24 saleId_)
        internal
        view
        returns (uint128)
    {
        if (priceType_ == PriceType.FIXED) {
            return fixedPrices[saleId_];
        }

        if (priceType_ == PriceType.DECLIINING_BY_TIME) {
            DecliningPrice storage price_ = decliningPrices[saleId_];
            if (block.timestamp >= price_.startTime + price_.duration) {
                return price_.lowest;
            }
            if (block.timestamp <= price_.startTime) {
                return price_.highest;
            }

            uint256 lastPrice =
                price_.highest -
                    ((block.timestamp - price_.startTime) / price_.interval) *
                    (((price_.highest - price_.lowest) / price_.duration) *
                        price_.interval);
            uint256 price256 = lastPrice < price_.lowest ? price_.lowest : lastPrice;
            require(price256 <= uint128(-1), "price: exceeds uint128 max");

            return uint128(price256);
        }

        revert("unsupported priceType");
    }

    function setFixedPrice(uint24 saleId_, uint128 price_) internal {
        fixedPrices[saleId_] = price_;
    }

    function setDecliningPrice(
        uint24 saleId_,
        uint32 startTime_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) internal {
        decliningPrices[saleId_].startTime = startTime_;
        decliningPrices[saleId_].highest = highest_;
        decliningPrices[saleId_].lowest = lowest_;
        decliningPrices[saleId_].duration = duration_;
        decliningPrices[saleId_].interval = interval_;
    }
}
