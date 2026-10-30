package com.stk.stock;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerTest {

    @Autowired
    MockMvc mvc;

    @Test
    void createReturns201AndTheOrder() throws Exception {
        mvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"item\":\"keyboard\",\"quantity\":2}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.item").value("keyboard"))
                .andExpect(jsonPath("$.status").value("NEW"));
    }

    @Test
    void zeroQuantityIsRejected() throws Exception {
        mvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"item\":\"keyboard\",\"quantity\":0}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void unknownOrderReturns404() throws Exception {
        mvc.perform(get("/api/orders/9999")).andExpect(status().isNotFound());
    }

    @Test
    void healthIsUp() throws Exception {
        mvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}
