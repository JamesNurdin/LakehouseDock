WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
full_joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_list_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        i.i_brand,
        i.i_category,
        i.i_units,
        i.i_size,
        i.i_container,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM sampled_sales cs
    FULL OUTER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
)
SELECT
    COALESCE(fj.i_brand, 'UNKNOWN') AS brand,
    COALESCE(fj.i_category, 'UNKNOWN') AS category,
    fj.hd_income_band_sk,
    SUM(fj.cs_ext_sales_price) AS total_sales,
    AVG(fj.cs_net_profit) AS avg_profit,
    COUNT(*) AS sales_count,
    MIN(fj.cs_list_price) AS min_list_price,
    MAX(fj.cs_list_price) AS max_list_price
FROM full_joined fj
WHERE
    (fj.i_units = 'Dozen' OR fj.i_units IS NULL)
    AND fj.i_size = 'medium'
    AND fj.cs_list_price > 50
    AND (fj.hd_dep_count <= 5 OR fj.hd_dep_count IS NULL)
    AND NOT EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_demo_sk = fj.hd_demo_sk
          AND hd2.hd_vehicle_count < 0
    )
GROUP BY
    COALESCE(fj.i_brand, 'UNKNOWN'),
    COALESCE(fj.i_category, 'UNKNOWN'),
    fj.hd_income_band_sk
ORDER BY total_sales DESC
LIMIT 100
