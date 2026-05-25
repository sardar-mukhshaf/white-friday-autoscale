from locust import FastHttpUser, task, between
import random

class WhiteFridayUser(FastHttpUser):
    wait_time = between(1, 3)
    host = "https://whitefriday.example.com"

    def on_start(self):
        self.client.get("/")

    @task(5)
    def homepage(self):
        with self.client.get("/", catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Homepage failed: {response.status_code}")
            elif response.elapsed.total_seconds() > 0.2:
                response.failure(f"Homepage too slow: {response.elapsed.total_seconds()}s")

    @task(4)
    def search_products(self):
        query = random.choice(["laptop", "phone", "shoes", "watch", "camera", "headphones"])
        with self.client.get(f"/api/products/search?q={query}&limit=20", catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Search failed: {response.status_code}")
            elif response.elapsed.total_seconds() > 0.2:
                response.failure(f"Search too slow: {response.elapsed.total_seconds()}s")

    @task(3)
    def view_product(self):
        product_id = random.randint(1, 10000)
        with self.client.get(f"/api/products/{product_id}", catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Product view failed: {response.status_code}")

    @task(2)
    def add_to_cart(self):
        product_id = random.randint(1, 10000)
        payload = {"productId": product_id, "quantity": random.randint(1, 3)}
        with self.client.post("/api/cart/items", json=payload, catch_response=True) as response:
            if response.status_code not in [200, 201]:
                response.failure(f"Add to cart failed: {response.status_code}")

    @task(1)
    def checkout(self):
        payload = {
            "items": [{"productId": random.randint(1, 10000), "quantity": 1}],
            "shippingAddress": {"city": "Riyadh", "country": "SA"},
            "paymentMethod": "credit_card"
        }
        with self.client.post("/api/orders", json=payload, catch_response=True) as response:
            if response.status_code not in [200, 201]:
                response.failure(f"Checkout failed: {response.status_code}")
            elif response.elapsed.total_seconds() > 0.5:
                response.failure(f"Checkout too slow: {response.elapsed.total_seconds()}s")

    @task(1)
    def payment_callback(self):
        payload = {
            "orderId": f"ORD-{random.randint(100000, 999999)}",
            "status": "success",
            "transactionId": f"TXN-{random.randint(100000, 999999)}"
        }
        with self.client.post("/api/payments/callback", json=payload, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Payment callback failed: {response.status_code}")
