-- goal: Rank warehouses and ship modes by total net profit, showing only those with high‑value returns and applying several filters.
WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        ca.ca_state,
        ca.ca_address_sk,
        SUM(cs.cs_net_profit)                         AS total_net_profit,
        SUM(cs.cs_ext_ship_cost)                      AS total_ship_cost,
        COUNT(DISTINCT cs.cs_order_number)            AS distinct_orders,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_ship_cost > 500                                   -- filter 1: expensive shipping
      AND cs.cs_ext_list_price BETWEEN 3000 AND 8000                 -- filter 2: mid‑to‑high list price
      AND sm.sm_contract <> 'Ek'                                      -- filter 3: exclude a specific contract
    GROUP BY
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        ca.ca_state,
        ca.ca_address_sk,
        sm.sm_contract
)
SELECT DISTINCT
    w.w_warehouse_name,
    sm.sm_type,
    s.ca_state,
    s.total_net_profit,
    s.total_ship_cost,
    s.distinct_orders,
    s.profit_status,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank,
    (
        SELECT AVG(sr.sr_return_amt_inc_tax)
        FROM store_returns sr
        WHERE sr.sr_addr_sk = s.ca_address_sk
          AND sr.sr_return_amt_inc_tax > 1000
    ) AS avg_high_return_amt
FROM sales_agg s
JOIN warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_addr_sk = s.ca_address_sk
      AND sr.sr_return_amt_inc_tax > 5000
)
AND s.total_net_profit > 0                      -- additional outer filter
ORDER BY profit_rank
LIMIT 100
