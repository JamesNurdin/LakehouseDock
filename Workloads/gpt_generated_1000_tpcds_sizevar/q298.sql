/*
  Goal: Summarize sales performance by ship mode, applying realistic filters, sampling the large catalog_sales table, and ensuring each result row has at least one matching EXPRESS ship mode via a correlated EXISTS sub‑query. The result is ordered by total sales and paginated (first 100 rows).
*/
WITH cs_agg AS (
    SELECT
        cs_ship_mode_sk,
        SUM(cs_ext_sales_price)        AS total_sales,
        AVG(cs_quantity)               AS avg_qty,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        MIN(cs_ext_wholesale_cost)     AS min_wholesale,
        MAX(cs_ext_wholesale_cost)     AS max_wholesale
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)               -- sample 10 % of rows
    WHERE cs_ext_wholesale_cost > 1000        -- predicate 1
      AND cs_list_price BETWEEN 20 AND 200   -- predicate 2
      AND cs_quantity <= 10                  -- predicate 3
      AND cs_ship_cdemo_sk IN (90299, 189998) -- predicate 4
    GROUP BY cs_ship_mode_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    sm.sm_code,
    cs_agg.total_sales,
    cs_agg.avg_qty,
    cs_agg.order_cnt,
    cs_agg.min_wholesale,
    cs_agg.max_wholesale
FROM cs_agg
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_contract LIKE 'U%'                -- predicate 5
  AND sm.sm_code IN ('AIR', 'SEA')            -- predicate 6
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = cs_agg.cs_ship_mode_sk
          AND sm2.sm_type = 'EXPRESS'
      )
ORDER BY cs_agg.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
