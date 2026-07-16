WITH inv_item_agg AS (
    SELECT i.i_category,
           i.i_class,
           SUM(inv.inv_quantity_on_hand) AS total_quantity,
           COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count,
           AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND i.i_current_price IS NOT NULL
    GROUP BY i.i_category, i.i_class
),
 demo_income_agg AS (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           COUNT(*) AS household_count,
           AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
           SUM(CASE WHEN hd.hd_buy_potential = '1001-5000' THEN 1 ELSE 0 END) AS high_buy_potential_cnt
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 'inventory' AS source,
       i_category,
       i_class,
       total_quantity,
       warehouse_count,
       avg_price,
       CAST(NULL AS INTEGER) AS income_band_sk,
       CAST(NULL AS BIGINT) AS household_count,
       CAST(NULL AS DOUBLE) AS avg_vehicle_count,
       CAST(NULL AS BIGINT) AS high_buy_potential_cnt
FROM inv_item_agg
UNION ALL
SELECT 'demographics' AS source,
       CAST(NULL AS VARCHAR) AS i_category,
       CAST(NULL AS VARCHAR) AS i_class,
       CAST(NULL AS BIGINT) AS total_quantity,
       CAST(NULL AS BIGINT) AS warehouse_count,
       CAST(NULL AS DOUBLE) AS avg_price,
       ib_income_band_sk AS income_band_sk,
       household_count,
       avg_vehicle_count,
       high_buy_potential_cnt
FROM demo_income_agg
ORDER BY source,
         total_quantity DESC NULLS LAST,
         household_count DESC NULLS LAST
LIMIT 200
