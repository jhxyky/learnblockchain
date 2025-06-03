package com.blockchain;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class Block {
    private int index;
    private long timestamp;
    private List<Transaction> transactions;
    private long proof;
    private String previousHash;

    public Block(int index, List<Transaction> transactions, String previousHash) {
        this.index = index;
        this.timestamp = Instant.now().getEpochSecond();
        this.transactions = new ArrayList<>(transactions);
        this.previousHash = previousHash;
        
        System.out.println("\n准备挖掘区块 #" + index);
        System.out.println("├── 前一个区块哈希: " + previousHash);
        System.out.println("├── 交易数量: " + transactions.size());
        System.out.println("└── 开始计算工作量证明...");
        
        this.proof = findProof();
    }

    // 工作量证明算法
    private long findProof() {
        long proof = 0;
        long attempts = 0;
        String targetPrefix = "0000"; // 目标难度：4个0

        while (!isValidProof(proof)) {
            proof++;
            attempts++;
            if (attempts % 100000 == 0) {
                System.out.println("   已尝试 " + attempts + " 次...");
            }
        }

        String hash = calculateHashWithProof(proof);
        System.out.println("找到有效的工作量证明!");
        System.out.println("├── 尝试次数: " + attempts);
        System.out.println("├── Proof值: " + proof);
        System.out.println("└── 区块哈希: " + hash);
        
        return proof;
    }

    // 验证工作量证明是否有效
    private boolean isValidProof(long proof) {
        String hash = calculateHashWithProof(proof);
        return hash.startsWith("0000");
    }

    // 计算包含proof的完整区块哈希
    private String calculateHashWithProof(long proof) {
        String blockData = String.format("%d%d%s%s%d", 
            index, 
            timestamp, 
            transactions.toString(), 
            previousHash,
            proof);
        return calculateHash(blockData);
    }

    // 计算SHA-256哈希值
    public static String calculateHash(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    public String getHash() {
        return calculateHashWithProof(proof);
    }

    public int getIndex() {
        return index;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public List<Transaction> getTransactions() {
        return transactions;
    }

    public long getProof() {
        return proof;
    }

    public String getPreviousHash() {
        return previousHash;
    }

    @Override
    public String toString() {
        return String.format("Block %d {previousHash='%s', transactions=%d, proof=%d, hash='%s'}",
                index, previousHash.substring(0, 10) + "...", 
                transactions.size(), proof, getHash().substring(0, 10) + "...");
    }
} 