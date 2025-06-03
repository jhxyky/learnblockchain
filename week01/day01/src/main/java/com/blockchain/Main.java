package com.blockchain;

public class Main {
    public static void main(String[] args) {
        // 创建区块链实例
        Blockchain blockchain = new Blockchain();

        // 注册矿工
        blockchain.registerMiner("矿工A");
        blockchain.registerMiner("矿工B");
        blockchain.registerMiner("矿工C");

        System.out.println("\n=== 第一轮挖矿 ===");
        // 添加一些交易
        blockchain.addTransaction(new Transaction("Alice", "Bob", 50));
        blockchain.addTransaction(new Transaction("Bob", "Charlie", 30));
        
        // 开始竞争挖矿
        blockchain.startMining();
        
        System.out.println("\n=== 第二轮挖矿 ===");
        // 添加更多交易
        blockchain.addTransaction(new Transaction("Charlie", "David", 20));
        blockchain.addTransaction(new Transaction("David", "Alice", 15));
        blockchain.addTransaction(new Transaction("Alice", "Eve", 25));
        
        // 再次开始竞争挖矿
        blockchain.startMining();

        // 打印整个区块链
        System.out.println("\n完整区块链:");
        System.out.println(blockchain);
    }
} 