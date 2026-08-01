WITH sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        i.i_category,
        i.i_category_id,
        i.i_class,
        i.i_class_id,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_units = 'Dozen'
      AND i.i_size = 'large'
      AND i.i_class_id IN (5, 12)
      AND ws.ws_ext_ship_cost BETWEEN 1000 AND 2000
      AND ws.ws_coupon_amt < 200
      AND sm.sm_code = 'AIR'
    GROUP BY ws.ws_item_sk, ws.ws_ship_mode_sk, i.i_category, i.i_category_id, i.i_class, i.i_class_id, i.i_brand
)
SELECT
    sa.i_category,
    sa.i_category_id,
    sa.i_class,
    sa.i_class_id,
    COALESCE(sa.i_brand, 'UNKNOWN_BRAND') AS i_brand,
    sa.total_sales,
    sa.total_profit,
    sa.avg_ship_cost,
    sa.order_cnt,
    RANK() OVER (PARTITION BY sa.i_category ORDER BY sa.total_profit DESC) AS profit_rank_in_category,
    ROW_NUMBER() OVER (PARTITION BY sa.i_class ORDER BY sa.total_sales DESC) AS sales_rownum_in_class,
    CASE
        WHEN sa.avg_ship_cost > 1500 THEN 'HIGH'
        WHEN sa.avg_ship_cost BETWEEN 1200 AND 1500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS ship_cost_category
FROM sales_agg sa
ORDER BY sa.i_category, profit_rank_in_category
LIMIT 100
