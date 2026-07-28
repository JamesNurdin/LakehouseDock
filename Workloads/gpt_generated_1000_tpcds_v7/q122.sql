SELECT
    d.d_year,
    d.d_month_seq,
    hd.hd_income_band_sk,
    p.p_discount_active,
    wp.wp_type,
    wsite.web_state,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND hd.hd_vehicle_count >= 2
  AND p.p_discount_active = 'Y'
  AND wp.wp_type = 'content'
  AND wsite.web_state = 'TX'
  AND inv.inv_warehouse_sk = 12
  AND inv.inv_quantity_on_hand > 0
  AND ws.ws_net_paid > 100
GROUP BY
    d.d_year,
    d.d_month_seq,
    hd.hd_income_band_sk,
    p.p_discount_active,
    wp.wp_type,
    wsite.web_state
ORDER BY total_net_paid DESC
LIMIT 100
