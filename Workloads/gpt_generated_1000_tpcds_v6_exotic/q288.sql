WITH overall_avg AS (
    SELECT AVG(cs2.cs_net_profit) AS avg_profit
    FROM catalog_sales cs2
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    sm.sm_code,
    hd.hd_buy_potential,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    COUNT(DISTINCT cr.cr_order_number) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    AVG(cs.cs_net_profit) AS avg_profit_per_sale,
    (SELECT avg_profit FROM overall_avg) AS overall_avg_profit
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
 AND ss.ss_promo_sk = p.p_promo_sk
JOIN web_sales ws
  ON ws.ws_promo_sk = p.p_promo_sk
 AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND sm.sm_code = 'AIR'
  AND p.p_discount_active = 'Y'
  AND wp.wp_image_count > 2
  AND wp.wp_max_ad_count <= 3
  AND wsite.web_country = 'USA'
  AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451920
GROUP BY p.p_promo_name, sm.sm_type, sm.sm_code, hd.hd_buy_potential, ws.ws_web_site_sk, ws.ws_order_number
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
