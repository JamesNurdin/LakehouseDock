/*
 Goal: Produce a multi‑source analytical view that combines store sales and catalog sales, applying deep joins to all 16 selected TPC‑DS tables, sampling inventory, using a CASE expression, a LATERAL subquery, UNION DISTINCT, EXCEPT, ranking per year, and distinct aggregates. The result shows the top‑5 profit rows per year after excluding the lowest‑ranked negative‑profit store‑sale rows, and returns the top‑k years ordered by total profit.
*/
WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)   -- sample 10% of inventory rows
),

s_store AS (
    SELECT
        d_store.d_year                         AS year,
        i.i_category                           AS category,
        CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        ss.ss_net_profit                      AS profit,
        ROW_NUMBER() OVER (PARTITION BY d_store.d_year ORDER BY ss.ss_net_profit DESC) AS rk,
        ss.ss_ticket_number,
        c.c_customer_id,
        ca.ca_state,
        s.s_store_name,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        lt.total_return
    FROM store_sales ss
    JOIN date_dim d_store          ON ss.ss_sold_date_sk   = d_store.d_date_sk
    JOIN time_dim td               ON ss.ss_sold_time_sk   = td.t_time_sk
    JOIN item i                    ON ss.ss_item_sk        = i.i_item_sk
    JOIN customer c                ON ss.ss_customer_sk    = c.c_customer_sk
    JOIN customer_address ca      ON ss.ss_addr_sk        = ca.ca_address_sk
    JOIN store s                   ON ss.ss_store_sk       = s.s_store_sk
    LEFT JOIN store_returns sr    ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r            ON sr.sr_reason_sk      = r.r_reason_sk
    LEFT JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_store.d_date_sk
    LEFT JOIN LATERAL (
        SELECT SUM(sr2.sr_return_amt) AS total_return
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_returned_date_sk = d_store.d_date_sk
    ) lt ON TRUE
    WHERE d_store.d_year = 2001
),

s_catalog AS (
    SELECT
        d_cat.d_year                         AS year,
        i2.i_category                        AS category,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        cs.cs_net_profit                     AS profit,
        ROW_NUMBER() OVER (PARTITION BY d_cat.d_year ORDER BY cs.cs_net_profit DESC) AS rk,
        cs.cs_order_number,
        c2.c_customer_id,
        ca2.ca_state,
        cc.cc_name,
        sm.sm_type
    FROM catalog_sales cs
    JOIN date_dim d_cat           ON cs.cs_sold_date_sk = d_cat.d_date_sk
    JOIN time_dim td2             ON cs.cs_sold_time_sk = td2.t_time_sk
    JOIN item i2                  ON cs.cs_item_sk      = i2.i_item_sk
    JOIN customer c2              ON cs.cs_bill_customer_sk = c2.c_customer_sk
    JOIN customer_address ca2    ON cs.cs_bill_addr_sk = ca2.ca_address_sk
    LEFT JOIN call_center cc     ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm       ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    WHERE d_cat.d_year = 2001
),

union_set AS (
    SELECT year, category, profit_flag, profit, rk FROM s_store
    UNION DISTINCT
    SELECT year, category, profit_flag, profit, rk FROM s_catalog
),

exclude_set AS (
    SELECT year, category, profit_flag, profit, rk
    FROM s_store
    WHERE profit_flag = 'NEG' AND rk <= 2   -- rows to be removed from the final set
),

final_set AS (
    SELECT * FROM union_set
    EXCEPT
    SELECT * FROM exclude_set
),

top_k AS (
    SELECT * FROM final_set WHERE rk <= 5   -- keep top‑5 rows per year
)
SELECT
    year,
    COUNT(DISTINCT category)      AS distinct_categories,
    COUNT(DISTINCT profit_flag)   AS distinct_profit_flags,
    SUM(profit)                    AS total_profit,
    MAX(rk)                        AS max_rank
FROM top_k
GROUP BY year
HAVING COUNT(DISTINCT category) > 1
ORDER BY total_profit DESC
LIMIT 100
