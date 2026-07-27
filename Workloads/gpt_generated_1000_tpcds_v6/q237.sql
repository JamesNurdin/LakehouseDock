WITH sales_agg AS (
    SELECT
        p.p_promo_name,
        sm.sm_carrier,
        td.t_time_id,
        wp.wp_url,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE p.p_channel_tv = 'N'
      AND td.t_am_pm = 'PM'
      AND ws.ws_list_price > 50
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ws.ws_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY p.p_promo_name, sm.sm_carrier, td.t_time_id, wp.wp_url
)
SELECT DISTINCT
    sa.p_promo_name,
    sa.sm_carrier,
    sa.t_time_id,
    sa.wp_url,
    sa.total_sales,
    sa.total_qty,
    RANK() OVER (PARTITION BY sa.p_promo_name ORDER BY sa.total_sales DESC) AS sales_rank,
    CASE
        WHEN sa.total_sales > (SELECT AVG(total_sales) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM sales_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100
