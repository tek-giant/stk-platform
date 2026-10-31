package com.stk.stock;

import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
public class OrderService {

    private final OrderRepository repository;

    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }

    public List<Order> list() {
        return repository.findAll(Sort.by("id")).stream()
                .map(OrderService::toOrder)
                .toList();
    }

    public Optional<Order> find(long id) {
        return repository.findById(id).map(OrderService::toOrder);
    }

    public Order create(String item, int quantity) {
        return toOrder(repository.save(new OrderEntity(item, quantity, "NEW")));
    }

    private static Order toOrder(OrderEntity entity) {
        return new Order(entity.getId(), entity.getItem(), entity.getQuantity(), entity.getStatus());
    }
}
