WITH avg_qty AS (
    SELECT cs_sold_date_sk, AVG(cs_quantity) AS avg_quantity
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
)
SELECT
    d.d_date AS sales_date,
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    w.w_warehouse_name,
    w.w_gmt_offset,
    p.p_promo_name,
    ws.ws_coupon_amt,
    wp.wp_url,
    site.web_name AS site_name,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_paid DESC) AS warehouse_rank,
    LAG(cs.cs_net_paid) OVER (PARTITION BY w.w_warehouse_name ORDER BY d.d_date) AS prev_net_paid,
    CASE WHEN cs.cs_quantity > (
        SELECT avg_quantity FROM avg_qty WHERE cs_sold_date_sk = cs.cs_sold_date_sk
    ) THEN 1 ELSE 0 END AS above_avg_qty
FROM date_dim d
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
WHERE d.d_year = 2001
  AND sm.sm_carrier = 'FEDEX'
  AND w.w_gmt_offset = -6.00
  AND p.p_discount_active = 'Y'
  AND ws.ws_coupon_amt > 100
ORDER BY cs.cs_net_paid DESC
LIMIT 100
