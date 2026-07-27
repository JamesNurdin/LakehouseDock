WITH ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        ws_sold_time_sk,
        SUM(ws_ext_sales_price) AS sum_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt,
        MIN(ws_ext_sales_price) AS min_sales,
        MAX(ws_ext_sales_price) AS max_sales
    FROM web_sales
    WHERE ws_list_price > 150.00
      AND ws_ext_sales_price > 200.00
    GROUP BY ws_bill_customer_sk, ws_sold_time_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws_agg.sum_sales) AS total_sales,
    AVG(ws_agg.avg_discount) AS avg_discount,
    SUM(ws_agg.order_cnt) AS total_orders,
    MIN(ws_agg.min_sales) AS min_sale,
    MAX(ws_agg.max_sales) AS max_sale
FROM ws_agg
JOIN customer c ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN time_dim t ON ws_agg.ws_sold_time_sk = t.t_time_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE t.t_sub_shift = 'morning'
  AND c.c_last_review_date BETWEEN 2452330 AND 2452549
  AND c.c_last_name = 'Combs'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_net_profit > 1000
    )
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
ORDER BY total_sales DESC
LIMIT 100
