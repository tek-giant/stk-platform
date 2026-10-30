package com.stk.stock;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.stereotype.Service;

@Service
public class OrderService {

    private final Map<Long, Order> orders = new ConcurrentHashMap<>();
    private final AtomicLong ids = new AtomicLong();

    public List<Order> list() {
        return orders.values().stream()
                .sorted(Comparator.comparingLong(Order::id))
                .toList();
    }

    public Optional<Order> find(long id) {
        return Optional.ofNullable(orders.get(id));
    }

    public Order create(String item, int quantity) {
        long id = ids.incrementAndGet();
        Order order = new Order(id, item, quantity, "NEW");
        orders.put(id, order);
        return order;
    }
}
