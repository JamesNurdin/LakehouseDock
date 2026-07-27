WITH ws_agg AS (
   SELECT
       ws.ws_item_sk,
       ws.ws_sold_date_sk,
       ws.ws_sold_time_sk,
       ws.ws_promo_sk,
       ws.ws_warehouse_sk,
       ws.ws_ship_mode_sk,
       ws.ws_web_page_sk,
       ws.ws_web_site_sk,
       ws.ws_bill_cdemo_sk,
       ws.ws_bill_hdemo_sk,
       d.d_year,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_quantity) AS total_quantity,
       COUNT(*) AS sales_transactions
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 1200 AND 1210
     AND ws.ws_quantity > 0
   GROUP BY
       ws.ws_item_sk,
       ws.ws_sold_date_sk,
       ws.ws_sold_time_sk,
       ws.ws_promo_sk,
       ws.ws_warehouse_sk,
       ws.ws_ship_mode_sk,
       ws.ws_web_page_sk,
       ws.ws_web_site_sk,
       ws.ws_bill_cdemo_sk,
       ws.ws_bill_hdemo_sk,
       d.d_year
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    w.w_warehouse_name,
    sm.sm_carrier,
    wp.wp_url,
    wsagg.total_sales,
    wsagg.total_quantity,
    wsagg.sales_transactions,
    cd.cd_gender,
    hd.hd_buy_potential,
    s.s_store_name,
    cr.cr_return_amount,
    sr.sr_return_amt,
    d.d_date,
    t.t_hour,
    t.t_am_pm
FROM ws_agg wsagg
JOIN item i ON wsagg.ws_item_sk = i.i_item_sk
JOIN promotion p ON wsagg.ws_promo_sk = p.p_promo_sk
JOIN warehouse w ON wsagg.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON wsagg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON wsagg.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site ON wsagg.ws_web_site_sk = site.web_site_sk
JOIN customer_demographics cd ON wsagg.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON wsagg.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d ON wsagg.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t ON wsagg.ws_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cr.cr_return_amount > 50.00
  AND sr.sr_return_amt > 30.00
  AND p.p_discount_active = 'Y'
ORDER BY wsagg.total_sales DESC
LIMIT 100
