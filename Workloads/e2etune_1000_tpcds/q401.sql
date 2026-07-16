WITH store_sales AS (
    SELECT
        cs.cs_warehouse_sk AS store_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND cs.cs_ext_sales_price > 1000
    GROUP BY cs.cs_warehouse_sk
),
store_with_rank AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_id,
        ws.total_net_profit,
        ws.avg_discount,
        ws.total_quantity,
        ws.orders_cnt,
        RANK() OVER (PARTITION BY s.s_market_id ORDER BY ws.total_net_profit DESC) AS market_profit_rank
    FROM store_sales ws
    JOIN store s
        ON ws.store_sk = s.s_store_sk
)
SELECT
    swr.s_store_name,
    swr.s_city,
    swr.s_state,
    swr.s_market_id,
    swr.total_net_profit,
    swr.avg_discount,
    swr.total_quantity,
    swr.orders_cnt,
    swr.market_profit_rank,
    w.web_name AS market_name,
    w.web_city AS market_city
FROM store_with_rank swr
JOIN web_site w
    ON swr.s_market_id = w.web_mkt_id
WHERE swr.market_profit_rank <= 10
ORDER BY swr.s_market_id, swr.market_profit_rank
LIMIT 200
