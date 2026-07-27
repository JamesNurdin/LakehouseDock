WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_profit > 100
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs.cs_sold_time_sk IN (
          SELECT t.t_time_sk
          FROM time_dim t
          WHERE t.t_hour BETWEEN 9 AND 17
            AND t.t_shift = 'day'
      )
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = cs.cs_bill_addr_sk
            AND ca.ca_location_type = 'apartment'
            AND ca.ca_county = 'Mifflin County'
      )
)
SELECT
    c.c_customer_id,
    i.i_brand,
    t.t_hour,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    MIN(fs.cs_net_profit) AS min_profit,
    MAX(fs.cs_net_profit) AS max_profit
FROM filtered_sales fs
JOIN customer c
    ON fs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i
    ON fs.cs_item_sk = i.i_item_sk
JOIN time_dim t
    ON fs.cs_sold_time_sk = t.t_time_sk
WHERE c.c_birth_country = 'United States'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    c.c_customer_id,
    i.i_brand,
    t.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
