WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_ship_mode_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_ext_sales_price > 500
      AND cs_quantity >= 1
      AND cs_net_paid_inc_ship < 5000
      AND cs_sold_time_sk IS NOT NULL
    GROUP BY cs_item_sk, cs_ship_mode_sk, cs_sold_time_sk
),
item_agg AS (
    SELECT
        i_item_sk,
        i_brand,
        i_category,
        ARRAY_AGG(DISTINCT i_color) AS colors,
        COUNT(DISTINCT i_color) AS distinct_colors
    FROM item
    WHERE i_current_price BETWEEN 100 AND 2000
    GROUP BY i_item_sk, i_brand, i_category
),
intersect_items AS (
    SELECT cs_item_sk FROM sales_agg
    WHERE EXISTS (
        SELECT 1 FROM time_dim td
        WHERE td.t_time_sk = sales_agg.cs_sold_time_sk
          AND td.t_hour < 6
    )
    INTERSECT
    SELECT i_item_sk FROM item
    WHERE i_current_price > 1500
),
max_price_per_brand AS (
    SELECT i_brand, MAX(i_current_price) AS max_price
    FROM item
    GROUP BY i_brand
),
joined AS (
    SELECT
        cagg.i_brand,
        cagg.i_category,
        sagg.total_sales,
        sagg.distinct_orders,
        sm.sm_code,
        sm.sm_ship_mode_sk,
        td.t_meal_time,
        td.t_am_pm,
        cagg.colors,
        mpb.max_price,
        u.color
    FROM sales_agg sagg
    JOIN item_agg cagg ON sagg.cs_item_sk = cagg.i_item_sk
    JOIN ship_mode sm ON sagg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON sagg.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN max_price_per_brand mpb ON cagg.i_brand = mpb.i_brand
    LEFT JOIN UNNEST(cagg.colors) AS u(color) ON TRUE
    WHERE sm.sm_contract NOT IN (
        SELECT sm2.sm_contract FROM ship_mode sm2 WHERE sm2.sm_code = 'AIR'
    )
      AND EXISTS (
        SELECT 1 FROM intersect_items ii WHERE ii.cs_item_sk = sagg.cs_item_sk
      )
      AND td.t_meal_time = 'BREAKFAST'
      AND td.t_am_pm = 'AM'
)
SELECT
    i_brand,
    i_category,
    AVG(total_sales) AS avg_total_sales,
    SUM(distinct_orders) AS sum_distinct_orders,
    COUNT(DISTINCT sm_ship_mode_sk) AS distinct_ship_modes,
    COUNT(DISTINCT sm_code) AS distinct_ship_codes,
    CASE WHEN AVG(total_sales) > 2000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_level,
    max_price,
    colors,
    color AS exploded_color
FROM joined
GROUP BY
    i_brand,
    i_category,
    max_price,
    colors,
    color
HAVING AVG(total_sales) > 1000
ORDER BY avg_total_sales DESC
LIMIT 100
