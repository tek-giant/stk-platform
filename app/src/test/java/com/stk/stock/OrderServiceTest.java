package com.stk.stock;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class OrderServiceTest {

    @Autowired
    OrderService service;

    @Test
    void createAssignsIncreasingIds() {
        Order first = service.create("keyboard", 1);
        Order second = service.create("mouse", 2);
        assertTrue(second.id() > first.id());
    }

    @Test
    void findReturnsCreatedOrder() {
        Order created = service.create("keyboard", 3);
        assertEquals(created, service.find(created.id()).orElseThrow());
        assertEquals("NEW", created.status());
    }

    @Test
    void findUnknownIsEmpty() {
        assertTrue(service.find(999999).isEmpty());
    }

    @Test
    void listIncludesCreatedOrders() {
        Order created = service.create("monitor", 1);
        assertTrue(service.list().contains(created));
    }
}
