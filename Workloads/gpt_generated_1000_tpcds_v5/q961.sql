WITH combined_metrics AS (
    SELECT ss_item_sk AS item_sk,
           ss_sold_time_sk AS time_sk,
           ss_customer_sk AS customer_sk,
           ss_cdemo_sk AS cdemo_sk,
           ss_hdemo_sk AS hdemo_sk,
           ss_ext_sales_price AS metric_value,
           'sales' AS metric_type
    FROM store_sales
    WHERE ss_ext_sales_price > 100

    UNION ALL

    SELECT cr_item_sk AS item_sk,
           cr_returned_time_sk AS time_sk,
           cr_refunded_customer_sk AS customer_sk,
           cr_refunded_cdemo_sk AS cdemo_sk,
           cr_refunded_hdemo_sk AS hdemo_sk,
           -cr_return_amount AS metric_value,
           'return' AS metric_type
    FROM catalog_returns
    WHERE cr_return_amount > 100
),
brand_avg AS (
    SELECT i.i_brand,
           AVG(cm.metric_value) AS avg_metric_value
    FROM combined_metrics cm
    JOIN item i ON cm.item_sk = i.i_item_sk
    GROUP BY i.i_brand
)
SELECT
    i.i_item_id,
    i.i_brand,
    t.t_hour,
    c.c_first_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    cm.metric_type,
    cm.metric_value,
    CASE
        WHEN cm.metric_value >= 1000 THEN 'High'
        WHEN cm.metric_value >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS value_category,
    RANK() OVER (PARTITION BY t.t_hour, cm.metric_type ORDER BY cm.metric_value DESC) AS metric_rank,
    ba.avg_metric_value
FROM combined_metrics cm
JOIN item i ON cm.item_sk = i.i_item_sk
JOIN time_dim t ON cm.time_sk = t.t_time_sk
JOIN customer c ON cm.customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cm.cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cm.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN brand_avg ba ON i.i_brand = ba.i_brand
WHERE t.t_hour BETWEEN 9 AND 17
  AND i.i_brand = 'Brand#23'
  AND c.c_birth_year BETWEEN 1960 AND 1980
  AND ib.ib_upper_bound <= 50000
  AND hd.hd_buy_potential = '>10000'
ORDER BY t.t_hour, metric_rank
LIMIT 100
