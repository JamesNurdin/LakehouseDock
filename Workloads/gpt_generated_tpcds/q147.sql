WITH aggregated_sales AS (
    SELECT
        b.c_customer_sk AS bill_cust_sk,
        b.c_first_name AS bill_first_name,
        b.c_last_name AS bill_last_name,
        s.c_customer_sk AS ship_cust_sk,
        s.c_first_name AS ship_first_name,
        s.c_last_name AS ship_last_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN customer b ON cs.cs_bill_customer_sk = b.c_customer_sk
    JOIN customer s ON cs.cs_ship_customer_sk = s.c_customer_sk
    WHERE cs.cs_quantity > 0
    GROUP BY
        b.c_customer_sk,
        b.c_first_name,
        b.c_last_name,
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name
)
SELECT
    bill_cust_sk,
    bill_first_name,
    bill_last_name,
    ship_cust_sk,
    ship_first_name,
    ship_last_name,
    total_net_paid,
    total_net_profit,
    avg_discount_amount,
    order_count,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
FROM aggregated_sales
ORDER BY total_net_paid DESC
LIMIT 20
