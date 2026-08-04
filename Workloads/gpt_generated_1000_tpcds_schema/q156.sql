WITH ws_agg AS (
    SELECT
        ws_web_site_sk,
        ws_bill_hdemo_sk,
        ws_web_page_sk,
        ws_promo_sk,
        SUM(ws_ext_sales_price)      AS total_sales,
        SUM(ws_ext_discount_amt)     AS total_discount,
        COUNT(*)                     AS order_cnt,
        AVG(ws_net_profit)           AS avg_profit
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN 2452634 AND 2452707
    GROUP BY ws_web_site_sk, ws_bill_hdemo_sk, ws_web_page_sk, ws_promo_sk
)
SELECT
    s.web_name,
    s.web_mkt_id,
    yr.year,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    wp.wp_type,
    wp.wp_link_count,
    p.p_promo_name,
    p.p_discount_active,
    SUM(ws_agg.total_sales)      AS site_total_sales,
    SUM(ws_agg.order_cnt)        AS site_order_cnt,
    AVG(ws_agg.avg_profit)       AS site_avg_profit,
    SUM(ws_agg.total_discount)   AS site_total_discount
FROM ws_agg
JOIN household_demographics hd
    ON ws_agg.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p
    ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN web_site s
    ON ws_agg.ws_web_site_sk = s.web_site_sk
CROSS JOIN (VALUES 2022, 2023) AS yr(year)
WHERE hd.hd_buy_potential = '1001-5000'
  AND wp.wp_rec_end_date > DATE '2000-01-01'
  AND s.web_mkt_id IN (2, 3)
  AND p.p_purpose = 'Unknown'
GROUP BY
    s.web_name,
    s.web_mkt_id,
    yr.year,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    wp.wp_type,
    wp.wp_link_count,
    p.p_promo_name,
    p.p_discount_active
ORDER BY site_total_sales DESC
LIMIT 100
