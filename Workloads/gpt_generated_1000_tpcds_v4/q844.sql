/*
  Goal: Identify the most profitable customers (by source channel) across catalog and web sales, 
  enriched with their current address and warehouse details, while applying several business filters. 
  The query demonstrates pre‑aggregation, UNION ALL set operation, a scalar EXISTS filter, 
  CASE logic, and a ranking window function.
*/
WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk      AS cust_sk,
        cs.cs_warehouse_sk          AS wh_sk,
        SUM(cs.cs_net_profit)       AS total_profit,
        COUNT(*)                    AS order_cnt
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_discount_amt < 1000
    GROUP BY cs.cs_bill_customer_sk, cs.cs_warehouse_sk
),
ws_agg AS (
    SELECT
        ws.ws_bill_customer_sk      AS cust_sk,
        ws.ws_warehouse_sk          AS wh_sk,
        SUM(ws.ws_net_profit)       AS total_profit,
        COUNT(*)                    AS order_cnt
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 1
      AND ws.ws_ext_discount_amt < 1000
    GROUP BY ws.ws_bill_customer_sk, ws.ws_warehouse_sk
),
combined AS (
    SELECT cust_sk, wh_sk, total_profit, order_cnt, 'catalog' AS source
    FROM cs_agg
    UNION ALL
    SELECT cust_sk, wh_sk, total_profit, order_cnt, 'web' AS source
    FROM ws_agg
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    w.w_warehouse_name,
    comb.source,
    comb.total_profit,
    comb.order_cnt,
    CASE
        WHEN comb.total_profit > 10000 THEN 'HIGH'
        WHEN comb.total_profit > 0    THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY comb.source ORDER BY comb.total_profit DESC) AS profit_rank,
    SUM(comb.total_profit) OVER (PARTITION BY c.c_customer_sk) AS customer_cumulative_profit
FROM combined comb
JOIN tpcds.customer c
    ON comb.cust_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN tpcds.warehouse w
    ON comb.wh_sk = w.w_warehouse_sk
WHERE ca.ca_gmt_offset = -5.00                      -- filter 1: specific GMT offset
  AND ca.ca_zip LIKE '9%'                           -- filter 2: zip codes starting with 9
  AND c.c_birth_country = 'FIJI'                    -- filter 3: customers born in FIJI
  AND EXISTS (                                       -- scalar subquery filter
        SELECT 1
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_net_profit > 0
    )
ORDER BY comb.source, profit_rank
LIMIT 100
