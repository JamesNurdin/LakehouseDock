WITH item_info AS (
    SELECT i_item_sk,
           i_product_name,
           i_current_price,
           i_wholesale_cost,
           i_category
    FROM item
    WHERE i_current_price > 10.00
),
agg_high AS (
    SELECT ii.i_item_sk,
           ii.i_product_name,
           SUM(ss.ss_net_paid) AS total_paid,
           'high_vehicle' AS vehicle_group,
           (SELECT AVG(i2.i_wholesale_cost)
            FROM item i2
            WHERE i2.i_category = ii.i_category) AS avg_category_wholesale
    FROM store_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN item_info ii
      ON ss.ss_item_sk = ii.i_item_sk
    WHERE hd.hd_vehicle_count >= 2
    GROUP BY ii.i_item_sk,
             ii.i_product_name,
             ii.i_category
),
agg_zero AS (
    SELECT ii.i_item_sk,
           ii.i_product_name,
           SUM(ss.ss_net_paid) AS total_paid,
           'zero_vehicle' AS vehicle_group,
           (SELECT AVG(i2.i_wholesale_cost)
            FROM item i2
            WHERE i2.i_category = ii.i_category) AS avg_category_wholesale
    FROM store_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN item_info ii
      ON ss.ss_item_sk = ii.i_item_sk
    WHERE hd.hd_vehicle_count = 0
    GROUP BY ii.i_item_sk,
             ii.i_product_name,
             ii.i_category
)
SELECT combined.i_item_sk,
       combined.i_product_name,
       combined.total_paid,
       combined.vehicle_group,
       combined.avg_category_wholesale
FROM (
    SELECT * FROM agg_high
    UNION ALL
    SELECT * FROM agg_zero
) AS combined
WHERE combined.total_paid > 1000.00
ORDER BY combined.total_paid DESC
LIMIT 100
