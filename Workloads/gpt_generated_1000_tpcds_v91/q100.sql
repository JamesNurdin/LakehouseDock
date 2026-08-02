WITH cat_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(cr.cr_return_amount) AS cat_total_return,
        COUNT(*) AS cat_return_cnt,
        AVG(i.i_current_price) AS cat_avg_price,
        COUNT(DISTINCT cr.cr_order_number) AS cat_distinct_orders,
        cc.cc_name,
        sm.sm_type,
        p.p_promo_name,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        td.t_hour
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 100
      AND cc.cc_country = 'United States'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        cc.cc_name,
        sm.sm_type,
        p.p_promo_name,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        td.t_hour
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(wr.wr_return_amt) AS web_total_return,
        COUNT(*) AS web_return_cnt,
        AVG(i.i_current_price) AS web_avg_price,
        COUNT(DISTINCT wr.wr_order_number) AS web_distinct_orders,
        wp.wp_url,
        wp.wp_image_count,
        p.p_promo_name,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        td.t_hour
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 100
      AND wp.wp_image_count >= 5
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        wp.wp_url,
        wp.wp_image_count,
        p.p_promo_name,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        td.t_hour
),
full_joined AS (
    SELECT
        COALESCE(cat.i_item_sk, web.i_item_sk) AS i_item_sk,
        COALESCE(cat.i_item_id, web.i_item_id) AS i_item_id,
        COALESCE(cat.i_category, web.i_category) AS i_category,
        cat.cat_total_return,
        web.web_total_return,
        cat.cat_return_cnt,
        web.web_return_cnt,
        cat.cat_distinct_orders,
        web.web_distinct_orders,
        cat.cc_name,
        cat.sm_type,
        web.wp_url,
        web.wp_image_count,
        cat.p_promo_name AS cat_promo_name,
        web.p_promo_name AS web_promo_name,
        cat.hd_vehicle_count AS cat_hd_vehicle_count,
        web.hd_vehicle_count AS web_hd_vehicle_count,
        cat.ib_lower_bound AS cat_ib_lower_bound,
        web.ib_lower_bound AS web_ib_lower_bound,
        cat.inv_quantity_on_hand AS cat_inv_quantity,
        web.inv_quantity_on_hand AS web_inv_quantity,
        cat.t_hour AS cat_hour,
        web.t_hour AS web_hour
    FROM cat_agg cat
    FULL OUTER JOIN web_agg web
      ON cat.i_item_sk = web.i_item_sk
),
unioned AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_category,
        cat_total_return AS total_return,
        'catalog' AS source
    FROM cat_agg
    UNION ALL
    SELECT
        i_item_sk,
        i_item_id,
        i_category,
        web_total_return AS total_return,
        'web' AS source
    FROM web_agg
),
final_agg AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_category,
        SUM(total_return) AS total_return_amount,
        COUNT(*) AS source_count
    FROM unioned
    GROUP BY i_item_sk, i_item_id, i_category
)
SELECT
    fa.i_item_id,
    fa.i_category,
    fa.total_return_amount,
    fa.source_count,
    RANK() OVER (ORDER BY fa.total_return_amount DESC) AS return_rank,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_item_sk = fa.i_item_sk) AS promo_count,
    fj.cc_name,
    fj.sm_type,
    fj.wp_url
FROM final_agg fa
LEFT JOIN full_joined fj ON fa.i_item_sk = fj.i_item_sk
WHERE fa.total_return_amount > 0
  AND fa.source_count >= 1
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = fa.i_item_sk
          AND cr2.cr_return_amount > 0
    )
ORDER BY fa.total_return_amount DESC
LIMIT 100
