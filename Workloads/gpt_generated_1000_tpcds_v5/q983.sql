WITH distinct_pages AS (
    SELECT DISTINCT wp_customer_sk, wp_web_page_id
    FROM web_page
    WHERE wp_link_count >= 10
),
sales AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        c.c_customer_id,
        ca.ca_state,
        sm.sm_type,
        sm.sm_contract
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN distinct_pages dp
        ON dp.wp_customer_sk = c.c_customer_sk
    WHERE sm.sm_type = 'OVERNIGHT'
      AND sm.sm_contract = 'hGoF18SLDDPBj'
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_ext_discount_amt > 0
)
SELECT
    ca_state,
    sm_type,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    COUNT(*) AS row_count
FROM sales
GROUP BY CUBE (ca_state, sm_type)
ORDER BY ca_state, sm_type
LIMIT 100
