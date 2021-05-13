package Exchange;

import ActiveIndexes.ActiveIndexes;
import Require.Require;

import java.util.HashMap;
import java.util.Map;

public class Exchange {

    String pionAddress = "0xPION";
    public Map<String, ActiveIndexes> tokenIndexes = new HashMap();
    public final Require rq = new Require(); //for internal use as solidity's require!

    public void setPionAddress(String pionAddress){ //onlyowner
        this.pionAddress = pionAddress;
    }

    private void addToken(String tokenAddress){
        tokenIndexes.put(tokenAddress, new ActiveIndexes(tokenAddress, pionAddress));
    }

    public void buyPion(String forToken, String userAddress, int priceIndex, int amount) throws Exception {
        if(!tokenIndexes.containsKey(forToken)){
            addToken(forToken);
        }
        tokenIndexes.get(forToken).buy(userAddress, priceIndex, amount);
    }

    public void sellPion(String forToken, String userAddress, int priceIndex, int amount) throws Exception {
        if(!tokenIndexes.containsKey(forToken)){
            addToken(forToken);
        }
        tokenIndexes.get(forToken).sell(userAddress, priceIndex, amount);
    }

    public void cancelOrders(String forToken, String userAddress, int priceIndex) throws Exception {
        tokenIndexes.get(forToken).cancelAt(userAddress, priceIndex);
    }

    public void withdrawAll(String forToken, String userAddress, int priceIndex) throws Exception {
        tokenIndexes.get(forToken).withdraw(userAddress, priceIndex);
    }

    public int[] getTradeData(String forToken, int tradePlaces) throws Exception {
        return tokenIndexes.get(forToken).getTradeData(tradePlaces);
    }

    public int getWithdrawBuyData(String forToken, String userAddress, int priceIndex) throws Exception {
        return tokenIndexes.get(forToken).getWithdrawAmountBuy(userAddress, priceIndex);
    }

    public int getWithdrawSellData(String forToken, String userAddress, int priceIndex) throws Exception {
        return tokenIndexes.get(forToken).getWithdrawAmountSell(userAddress, priceIndex);
    }
    //--------------------------------
    public int token2TokenCalculate(String sellToken, String buyToken, int amount) throws Exception {
        int pions = tokenIndexes.get(sellToken).currentToPionConversion(amount);
        int buyTokens = tokenIndexes.get(buyToken).currentToTokenConversion(pions);
        return buyTokens;
    }
    //how many current peons are circulating
    public int token2TokenGetPionAmount(String sellToken) throws Exception {
        return tokenIndexes.get(sellToken).getCurrentSellAmount();
    }
    //how many tokens user is asking for are circulating
    public int token2TokenGetTokenAmount(String buyToken) throws Exception {
        return tokenIndexes.get(buyToken).getCurrentBuyAmount();
    }



}
