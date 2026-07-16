WITH store_agg AS (
    SELECT
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        AVG(ss.ss_ext_discount_amt) AS store_avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_unique_customers,
        COUNT(*) AS store_transactions
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_shift = 'Evening'
      AND i.i_category = 'Electronics'
    GROUP BY ca.ca_state, i.i_category
),
web_agg AS (
    SELECT
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        AVG(ws.ws_ext_discount_amt) AS web_avg_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_unique_customers,
        COUNT(*) AS web_transactions
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE td.t_shift = 'Evening'
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'Air'
      AND wh.w_state = 'CA'
    GROUP BY ca.ca_state, i.i_category
)
SELECT
    COALESCE(s.state, w.state) AS state,
    COALESCE(s.category, w.category) AS category,
    COALESCE(s.store_net_profit, 0) AS store_net_profit,
    COALESCE(w.web_net_profit, 0) AS web_net_profit,
    (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit,
    (COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0)) AS total_sales,
    (COALESCE(s.store_transactions, 0) + COALESCE(w.web_transactions, 0)) AS total_transactions,
    ROUND(
        (COALESCE(s.store_avg_discount, 0) * COALESCE(s.store_transactions, 0) +
         COALESCE(w.web_avg_discount, 0) * COALESCE(w.web_transactions, 0))
        /
        NULLIF((COALESCE(s.store_transactions, 0) + COALESCE(w.web_transactions, 0)), 0)
    , 2) AS weighted_avg_discount,
    RANK() OVER (ORDER BY (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0)) DESC) AS profit_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.state = w.state AND s.category = w.category
WHERE (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 20
