WITH ws_agg AS (
    SELECT
        ws_bill_hdemo_sk,
        ws_sold_time_sk,
        SUM(ws_ext_sales_price) AS sum_sales,
        SUM(ws_net_profit) AS sum_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_ext_tax > 20
      AND ws_list_price BETWEEN 20 AND 150
    GROUP BY ws_bill_hdemo_sk, ws_sold_time_sk
)
SELECT
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'High' ELSE 'Low' END AS vehicle_category,
    td.t_meal_time,
    SUM(ws_agg.sum_sales) AS total_sales,
    SUM(ws_agg.sum_profit) AS total_profit,
    COUNT(*) AS group_rows
FROM ws_agg
JOIN household_demographics hd
    ON ws_agg.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN time_dim td
    ON ws_agg.ws_sold_time_sk = td.t_time_sk
WHERE hd.hd_dep_count >= 2
  AND hd.hd_income_band_sk IN (4, 7, 14)
  AND td.t_second IN (16, 18, 0, 7)
  AND td.t_meal_time = 'dinner'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws3
        WHERE ws3.ws_ship_hdemo_sk = hd.hd_demo_sk
          AND ws3.ws_quantity > 5
    )
GROUP BY
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    td.t_meal_time
HAVING SUM(ws_agg.sum_sales) > 1000
ORDER BY total_sales DESC
LIMIT 100
