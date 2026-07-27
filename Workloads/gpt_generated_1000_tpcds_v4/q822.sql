WITH distinct_addr AS (
    SELECT DISTINCT
        ca_address_sk,
        ca_address_id,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
    WHERE regexp_like(ca_address_id, '^AAAAAAA[AE]')
      AND ca_state LIKE 'A%'
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    CASE
        WHEN ca.ca_state = 'CA' THEN 'West'
        WHEN ca.ca_state = 'NY' THEN 'East'
        ELSE 'Other'
    END AS region,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_profit,
    REGEXP_EXTRACT(ca.ca_address_id, '([A-Z])$', 1) AS last_char
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN distinct_addr ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND sm.sm_type LIKE '%AIR%'
GROUP BY
    w.w_warehouse_id,
    w.w_city,
    CASE
        WHEN ca.ca_state = 'CA' THEN 'West'
        WHEN ca.ca_state = 'NY' THEN 'East'
        ELSE 'Other'
    END,
    ca.ca_address_id,
    REGEXP_EXTRACT(ca.ca_address_id, '([A-Z])$', 1)
ORDER BY total_profit DESC
LIMIT 100
