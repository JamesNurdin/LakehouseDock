WITH bill_hdm AS (
    SELECT hd_demo_sk, hd_buy_potential
    FROM household_demographics
),
ship_hdm AS (
    SELECT hd_demo_sk
    FROM household_demographics
)
SELECT
    i.i_brand,
    w.w_city,
    bhd.hd_buy_potential,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(ws.ws_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(ws.ws_ext_wholesale_cost) AS max_wholesale_cost
FROM web_sales ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN bill_hdm bhd
    ON ws.ws_bill_hdemo_sk = bhd.hd_demo_sk
JOIN ship_hdm shd
    ON ws.ws_ship_hdemo_sk = shd.hd_demo_sk
WHERE i.i_units = 'Dozen'
  AND p.p_channel_demo = 'N'
  AND p.p_purpose = 'Unknown'
  AND ws.ws_ext_wholesale_cost > 1000
  AND ws.ws_net_paid_inc_tax BETWEEN 500 AND 3000
  AND w.w_state = 'CA'
  AND wp.wp_type = 'article'
  AND i.i_rec_end_date = DATE '2001-10-26'
GROUP BY i.i_brand, w.w_city, bhd.hd_buy_potential, wp.wp_type
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
