WITH sub1 AS (
   SELECT
       cs.cs_order_number AS order_number,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS sale_cnt,
       MIN(cs.cs_sold_date_sk) AS min_date_sk,
       MAX(cs.cs_sold_date_sk) AS max_date_sk
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
   JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                         AND ss.ss_item_sk = sr.sr_item_sk
   JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
   JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
   WHERE td.t_hour = 12
     AND i.i_brand = 'BrandX'
     AND w.w_city = 'New York'
   GROUP BY cs.cs_order_number
   HAVING SUM(cs.cs_ext_sales_price) > 1000
),
sub2 AS (
   SELECT
       ws.ws_order_number AS order_number,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(*) AS sale_cnt,
       MIN(ws.ws_sold_date_sk) AS min_date_sk,
       MAX(ws.ws_sold_date_sk) AS max_date_sk
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
   JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
   JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
   JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                         AND ss.ss_item_sk = sr.sr_item_sk
   JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
   WHERE td.t_meal_time = 'LUNCH'
     AND i.i_category = 'Electronics'
     AND webs.web_country = 'United States'
   GROUP BY ws.ws_order_number
   HAVING SUM(ws.ws_ext_sales_price) > 500
),
intersected AS (
   SELECT order_number,
          total_sales,
          sale_cnt,
          min_date_sk,
          max_date_sk
   FROM sub1
   INTERSECT
   SELECT order_number,
          total_sales,
          sale_cnt,
          min_date_sk,
          max_date_sk
   FROM sub2
)
SELECT
    intersected.*, 
    row_number() OVER (ORDER BY total_sales DESC) AS rn
FROM intersected
ORDER BY rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
