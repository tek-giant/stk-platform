package com.stk.stock;

public record Order(long id, String item, int quantity, String status) {
}
