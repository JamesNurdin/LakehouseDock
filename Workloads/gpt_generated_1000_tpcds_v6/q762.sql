WITH ws_agg AS (
   SELECT
       ws.ws_item_sk AS item_sk,
       ws.ws_web_site_sk AS web_site_sk,
       SUM(ws.ws_net_paid) AS ws_total_net_paid,
       COUNT(*) AS ws_order_cnt,
       AVG(ws.ws_ext_discount_amt) AS ws_avg_discount
   FROM web_sales ws
   JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
   JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
   JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
   JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
   JOIN web_site wsite_ws ON ws.ws_web_site_sk = wsite_ws.web_site_sk
   WHERE d_ws_sold.d_year = 2001
     AND t_ws_sold.t_meal_time = 'lunch'
     AND wsite_ws.web_country = 'United States'
     AND sm_ws.sm_type = 'AIR'
   GROUP BY ws.ws_item_sk, ws.ws_web_site_sk
)
SELECT
   i.i_item_id,
   i.i_product_name,
   cp.cp_department,
   cc.cc_name,
   d_sold.d_year,
   d_sold.d_month_seq,
   SUM(cs.cs_net_paid) AS total_sales,
   COUNT(DISTINCT cs.cs_order_number) AS order_count,
   AVG(cs.cs_ext_discount_amt) AS avg_discount,
   COALESCE(sr_total.sr_net_loss, 0) AS total_store_return_loss,
   COALESCE(cr_total.cr_net_loss, 0) AS total_catalog_return_loss,
   ws_agg.ws_total_net_paid,
   ws_agg.ws_order_cnt,
   ws_agg.ws_avg_discount
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS sr_net_loss
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    WHERE r_sr.r_reason_desc LIKE '%damaged%'
    GROUP BY sr.sr_item_sk
) sr_total ON sr_total.sr_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    WHERE r_cr.r_reason_desc LIKE '%defect%'
    GROUP BY cr.cr_item_sk
) cr_total ON cr_total.cr_item_sk = i.i_item_sk
JOIN ws_agg ON ws_agg.item_sk = i.i_item_sk
WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND cp.cp_department = 'Books'
  AND cc.cc_state = 'KY'
  AND i.i_brand = 'Brand#12'
  AND sm.sm_type = 'AIR'
  AND t_sold.t_hour BETWEEN 9 AND 17
GROUP BY
   i.i_item_id,
   i.i_product_name,
   cp.cp_department,
   cc.cc_name,
   d_sold.d_year,
   d_sold.d_month_seq,
   ws_agg.ws_total_net_paid,
   ws_agg.ws_order_cnt,
   ws_agg.ws_avg_discount,
   sr_total.sr_net_loss,
   cr_total.cr_net_loss
ORDER BY total_sales DESC
LIMIT 100
