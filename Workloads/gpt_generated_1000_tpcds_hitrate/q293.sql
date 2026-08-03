WITH base AS (
    SELECT
        ss.ss_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        ws.ws_order_number,
        ws.ws_net_profit,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        ca.ca_state,
        td.t_hour,
        cp.cp_department,
        CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discounted' ELSE 'FullPrice' END AS discount_flag
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE td.t_hour = 14
      AND ca.ca_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND cp.cp_department = 'Electronics'
      AND cs.cs_quantity > 2
),
filtered AS (
    SELECT *
    FROM base b
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = b.ws_order_number
          AND ws2.ws_net_profit > 0
    )
)
SELECT
    f.c_customer_id,
    f.ca_state,
    f.t_hour,
    f.discount_flag,
    COUNT(DISTINCT f.ws_order_number) AS distinct_orders,
    SUM(f.ss_net_paid) AS total_store_net_paid,
    AVG(f.cs_ext_sales_price) AS avg_catalog_sales_price,
    MIN(f.cs_quantity) AS min_quantity,
    MAX(f.cs_quantity) AS max_quantity
FROM filtered f
GROUP BY f.c_customer_id, f.ca_state, f.t_hour, f.discount_flag
ORDER BY total_store_net_paid DESC
LIMIT 100
