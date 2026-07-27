WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_id,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_txns
    FROM customer c
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_quantity_on_hand > 0
    WHERE
        ss.ss_sold_time_sk IN (66750, 56996, 49904)               -- predicate 1
        AND ss.ss_ext_list_price > 2000.00                         -- predicate 2
        AND ss.ss_quantity >= 1                                    -- predicate 3
        AND ws.ws_ext_discount_amt < 2000.00                       -- predicate 4
        AND ws.ws_ship_hdemo_sk = 4255                             -- predicate 5
        AND w.w_country = 'United States'                          -- predicate 6
        AND c.c_preferred_cust_flag = 'Y'                          -- predicate 7
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_id
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.w_warehouse_id,
    s.store_sales_total,
    s.web_sales_total,
    (s.store_sales_total + s.web_sales_total) AS total_sales,
    (s.store_profit + s.web_profit) / NULLIF(s.store_txns + s.web_txns, 0) AS avg_profit_per_txn
FROM sales_agg s
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = s.c_customer_sk
      AND ss2.ss_net_paid > 1000
)
ORDER BY total_sales DESC
LIMIT 100
