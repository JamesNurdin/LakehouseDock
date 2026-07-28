WITH sales_pre AS (
    SELECT
        ws_ship_mode_sk,
        ws_web_site_sk,
        ws_web_page_sk,
        SUM(ws_net_paid_inc_tax) AS sum_net_paid,
        AVG(ws_ext_ship_cost) AS avg_ship_cost,
        COUNT(*) AS cnt_sales
    FROM tpcds.web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451179
      AND ws_quantity > 1
      AND ws_ext_ship_cost > 100
      AND ws_net_paid_inc_tax > 500
    GROUP BY ws_ship_mode_sk, ws_web_site_sk, ws_web_page_sk
),
join_pre AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_carrier AS carrier,
        sm.sm_type AS ship_type,
        ws_pre.sum_net_paid,
        ws_pre.avg_ship_cost,
        ws_pre.cnt_sales,
        wp.wp_max_ad_count,
        wp.wp_image_count,
        ws_site.web_manager,
        ws_site.web_mkt_id
    FROM sales_pre ws_pre
    JOIN tpcds.ship_mode sm ON ws_pre.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp ON ws_pre.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site ws_site ON ws_pre.ws_web_site_sk = ws_site.web_site_sk
    WHERE sm.sm_carrier = 'FedEx'
      AND ws_site.web_mkt_id IN (1, 3, 5)
      AND wp.wp_max_ad_count >= 2
      AND wp.wp_image_count <= 5
)
SELECT
    ship_mode_id,
    carrier,
    COUNT(*) AS num_groups,
    SUM(sum_net_paid) AS total_net_paid,
    AVG(CASE WHEN ship_type = 'AIR' THEN avg_ship_cost * 1.1 ELSE avg_ship_cost END) AS avg_adjusted_ship_cost,
    MAX(cnt_sales) AS max_sales_cnt,
    (
        SELECT COUNT(*)
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_quantity > 5
    ) AS high_quantity_sales_cnt
FROM join_pre
GROUP BY ship_mode_id, carrier
HAVING SUM(sum_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
