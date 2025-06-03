package com.blockchain;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicBoolean;

public class Blockchain {
    private List<Block> chain;
    private List<Transaction> pendingTransactions;
    private List<Miner> miners;

    public Blockchain() {
        this.chain = new ArrayList<>();
        this.pendingTransactions = new CopyOnWriteArrayList<>();
        this.miners = new ArrayList<>();
        createGenesisBlock();
    }

    private void createGenesisBlock() {
        System.out.println("创建创世区块...");
        Block genesisBlock = new Block(0, new ArrayList<>(), "0");
        chain.add(genesisBlock);
    }

    public void registerMiner(String name) {
        miners.add(new Miner(name, this));
        System.out.println("矿工 " + name + " 加入网络");
    }

    public Block getLatestBlock() {
        return chain.get(chain.size() - 1);
    }

    public void addTransaction(Transaction transaction) {
        System.out.println("收到新交易: " + transaction);
        pendingTransactions.add(transaction);
        System.out.println("当前待处理交易数量: " + pendingTransactions.size());
    }

    public void startMining() {
        if (pendingTransactions.isEmpty()) {
            System.out.println("没有待处理的交易，无需挖矿");
            return;
        }

        System.out.println("\n开始新一轮挖矿竞争...");
        List<Transaction> transactionsToMine = new ArrayList<>(pendingTransactions);
        AtomicBoolean blockMined = new AtomicBoolean(false);

        // 所有矿工开始竞争挖矿
        List<Thread> miningThreads = new ArrayList<>();
        for (Miner miner : miners) {
            Thread thread = new Thread(() -> miner.startMining(transactionsToMine, blockMined));
            miningThreads.add(thread);
            thread.start();
        }

        // 等待所有矿工完成挖矿
        for (Thread thread : miningThreads) {
            try {
                thread.join();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        // 清空待处理交易
        pendingTransactions.clear();
        System.out.println("本轮挖矿完成，待处理交易列表已清空\n");
    }

    public void addBlock(Block block) {
        chain.add(block);
    }

    public List<Block> getChain() {
        return chain;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        for (Block block : chain) {
            sb.append(block.toString()).append("\n");
        }
        return sb.toString();
    }
} 