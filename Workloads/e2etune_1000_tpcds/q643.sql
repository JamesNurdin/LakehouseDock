WITH item_inventory AS (
    SELECT
        i.i_category,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(i.i_current_price) AS avg_price,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category IN ('Electronics', 'Furniture', 'Clothing')
      AND inv.inv_quantity_on_hand > 0
    GROUP BY i.i_category, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand) > 100
),
income_metrics AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        AVG(hd.hd_dep_count) AS avg_dependent_count,
        COUNT(*) AS household_cnt
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_income_band_sk IN (2, 3, 4)
      AND hd.hd_buy_potential = '1001-5000'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING COUNT(*) > 10
)
SELECT
    'ItemInventory' AS metric_type,
    i_category,
    i_brand,
    CAST(total_quantity AS BIGINT) AS total_quantity,
    CAST(avg_price AS DOUBLE) AS avg_price,
    warehouse_count,
    CAST(NULL AS INTEGER) AS income_band_sk,
    CAST(NULL AS DOUBLE) AS avg_vehicle_count,
    CAST(NULL AS DOUBLE) AS avg_dependent_count,
    CAST(NULL AS BIGINT) AS household_cnt
FROM item_inventory
UNION ALL
SELECT
    'IncomeMetrics' AS metric_type,
    CAST(NULL AS VARCHAR) AS i_category,
    CAST(NULL AS VARCHAR) AS i_brand,
    CAST(NULL AS BIGINT) AS total_quantity,
    CAST(NULL AS DOUBLE) AS avg_price,
    CAST(NULL AS BIGINT) AS warehouse_count,
    ib_income_band_sk AS income_band_sk,
    avg_vehicle_count,
    avg_dependent_count,
    household_cnt
FROM income_metrics
ORDER BY metric_type, total_quantity DESC, avg_vehicle_count DESC
