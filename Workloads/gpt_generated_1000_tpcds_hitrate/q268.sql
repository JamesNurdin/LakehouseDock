WITH agg_sales AS (
    SELECT
        cs_ship_mode_sk,
        SUM(cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cs_ext_ship_cost) AS total_ship_cost,
        COUNT(*) AS order_cnt
    FROM catalog_sales TABLESAMPLE BERNOULLI (5)
    WHERE cs_ext_ship_cost > 0
      AND cs_net_paid_inc_ship BETWEEN 1000 AND 5000
      AND cs_ext_tax < 200
    GROUP BY cs_ship_mode_sk
),
valid_modes AS (
    SELECT sm_ship_mode_sk
    FROM ship_mode
    WHERE sm_carrier IN ('DHL', 'GERMA', 'TBS')
      AND sm_contract LIKE 'P7F%'
),
excluded_modes AS (
    SELECT cs_ship_mode_sk AS sm_ship_mode_sk
    FROM catalog_sales
    WHERE cs_ext_tax > 300
),
allowed_modes AS (
    SELECT sm_ship_mode_sk
    FROM valid_modes
    EXCEPT
    SELECT sm_ship_mode_sk
    FROM excluded_modes
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    agg.total_net_paid,
    agg.total_ship_cost,
    agg.order_cnt
FROM agg_sales agg
JOIN ship_mode sm
    ON agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN allowed_modes am
    ON sm.sm_ship_mode_sk = am.sm_ship_mode_sk
ORDER BY agg.total_net_paid DESC
LIMIT 100
