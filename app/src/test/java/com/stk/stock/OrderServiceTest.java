package com.stk.stock;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class OrderServiceTest {

    @Test
    void createAssignsIncreasingIds() {
        OrderService service = new OrderService();
        assertEquals(1, service.create("keyboard", 1).id());
        assertEquals(2, service.create("mouse", 2).id());
    }

    @Test
    void findReturnsCreatedOrder() {
        OrderService service = new OrderService();
        Order created = service.create("keyboard", 3);
        assertEquals(created, service.find(created.id()).orElseThrow());
        assertEquals("NEW", created.status());
    }

    @Test
    void findUnknownIsEmpty() {
        assertTrue(new OrderService().find(99).isEmpty());
    }
}
