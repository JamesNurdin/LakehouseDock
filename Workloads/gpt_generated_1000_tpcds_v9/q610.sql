WITH sales_by_cust_wh AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_warehouse_sk AS warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MIN(ws.ws_net_profit) AS min_profit,
        MAX(ws.ws_net_profit) AS max_profit
    FROM web_sales ws
    WHERE ws.ws_ext_wholesale_cost BETWEEN 300 AND 4000
      AND ws.ws_net_paid_inc_tax > 2000
      AND ws.ws_quantity > 1
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450999
    GROUP BY ws.ws_bill_customer_sk, ws.ws_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_county,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.avg_net_paid_inc_tax, 0) AS avg_net_paid_inc_tax,
    COALESCE(s.order_cnt, 0) AS order_cnt,
    s.min_profit,
    s.max_profit,
    word
FROM warehouse w
LEFT JOIN sales_by_cust_wh s
    ON w.w_warehouse_sk = s.warehouse_sk
LEFT JOIN customer c
    ON s.customer_sk = c.c_customer_sk
    AND c.c_birth_year = 1975
CROSS JOIN UNNEST(split(w.w_warehouse_name, ' ')) AS t(word)
WHERE w.w_country = 'United States'
  AND w.w_county IN ('Marshall County', 'Williamson County')
  AND EXISTS (
      SELECT 1 FROM web_sales ws2
      WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
        AND ws2.ws_quantity > 10
  )
ORDER BY total_sales DESC
LIMIT 100
