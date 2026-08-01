WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_quantity > 1
),
eligible_orders AS (
    SELECT ws_order_number FROM sampled_sales
    EXCEPT
    SELECT ws_order_number FROM sampled_sales WHERE ws_promo_sk IS NULL
),
agg_part AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        ib.ib_income_band_sk,
        t.t_shift,
        SUM(s.ws_ext_sales_price) AS total_sales,
        AVG(i.i_current_price) AS avg_item_price,
        COUNT(DISTINCT s.ws_order_number) AS order_cnt,
        MAX(s.ws_net_profit) AS max_profit,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag,
        (SELECT COUNT(*) FROM promotion) AS total_promotions
    FROM sampled_sales s
    JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON s.ws_web_page_sk = wp.wp_web_page_sk
    RIGHT OUTER JOIN web_site ws ON s.ws_web_site_sk = ws.web_site_sk
    JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE s.ws_order_number IN (SELECT ws_order_number FROM eligible_orders)
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_upper_bound <= 50000
      AND i.i_current_price BETWEEN 10 AND 100
      AND t.t_shift = 'first'
      AND sm.sm_type = 'AIR'
      AND hd.hd_dep_count > 2
    GROUP BY ws.web_site_id, ws.web_name, ib.ib_income_band_sk, t.t_shift, p.p_discount_active
    HAVING SUM(s.ws_ext_sales_price) > 5000
),
agg_part2 AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        ib.ib_income_band_sk,
        t.t_shift,
        SUM(s.ws_ext_sales_price) AS total_sales,
        AVG(i.i_current_price) AS avg_item_price,
        COUNT(DISTINCT s.ws_order_number) AS order_cnt,
        MAX(s.ws_net_profit) AS max_profit,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag,
        (SELECT COUNT(*) FROM promotion) AS total_promotions
    FROM sampled_sales s
    JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON s.ws_web_page_sk = wp.wp_web_page_sk
    RIGHT OUTER JOIN web_site ws ON s.ws_web_site_sk = ws.web_site_sk
    JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE s.ws_order_number IN (SELECT ws_order_number FROM eligible_orders)
      AND hd.hd_vehicle_count = 0
      AND ib.ib_upper_bound <= 30000
      AND i.i_current_price BETWEEN 20 AND 80
      AND t.t_shift = 'second'
      AND sm.sm_type = 'RAIL'
      AND hd.hd_dep_count > 0
    GROUP BY ws.web_site_id, ws.web_name, ib.ib_income_band_sk, t.t_shift, p.p_discount_active
    HAVING SUM(s.ws_ext_sales_price) > 8000
)
SELECT *
FROM (
    SELECT * FROM agg_part
    UNION
    SELECT * FROM agg_part2
) AS unioned
WHERE total_sales > 10000
ORDER BY total_sales DESC
LIMIT 100
