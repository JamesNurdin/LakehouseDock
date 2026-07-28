WITH catalog_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(cs.cs_ext_sales_price)            AS sales_amount,
         COUNT(DISTINCT cs.cs_order_number)    AS metric_cnt
  FROM   tpcds.date_dim d
  JOIN   tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT   JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = cs.cs_item_sk
  LEFT   JOIN tpcds.reason r ON r.r_reason_sk = cr.cr_reason_sk
  LEFT   JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
  LEFT   JOIN tpcds.warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
  LEFT   JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
  LEFT   JOIN tpcds.promotion p ON p.p_promo_sk = cs.cs_promo_sk
  WHERE  d.d_year = 2001
    AND  p.p_discount_active = 'Y'
    AND  cs.cs_quantity > 0
    AND  cs.cs_sales_price > 10
    AND  cs.cs_ext_tax > 0
    AND  sm.sm_type = 'AIR'
    AND  w.w_state = 'CA'
    AND  r.r_reason_desc LIKE '%late%'
  GROUP BY d.d_year, d.d_month_seq
  HAVING SUM(cs.cs_ext_sales_price) > 10000
),
store_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(ss.ss_ext_sales_price)            AS sales_amount,
         COUNT(DISTINCT ss.ss_ticket_number)   AS metric_cnt
  FROM   tpcds.date_dim d
  JOIN   tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT   JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                                      AND sr.sr_item_sk = ss.ss_item_sk
                                      AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT   JOIN tpcds.reason r ON r.r_reason_sk = sr.sr_reason_sk
  LEFT   JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = ss.ss_promo_sk
  LEFT   JOIN tpcds.warehouse w ON w.w_warehouse_sk = ss.ss_store_sk
  LEFT   JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
  LEFT   JOIN tpcds.promotion p ON p.p_promo_sk = ss.ss_promo_sk
  WHERE  d.d_year = 2001
    AND  p.p_discount_active = 'Y'
    AND  ss.ss_quantity > 0
    AND  ss.ss_sales_price > 10
    AND  ss.ss_ext_tax > 0
    AND  sm.sm_type = 'AIR'
    AND  w.w_state = 'CA'
    AND  r.r_reason_desc LIKE '%late%'
  GROUP BY d.d_year, d.d_month_seq
  HAVING SUM(ss.ss_ext_sales_price) > 8000
),
web_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(ws.ws_ext_sales_price)            AS sales_amount,
         COUNT(DISTINCT ws.ws_order_number)    AS metric_cnt
  FROM   tpcds.date_dim d
  JOIN   tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT   JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                                      AND wr.wr_item_sk = ws.ws_item_sk
                                      AND wr.wr_order_number = ws.ws_order_number
  LEFT   JOIN tpcds.reason r ON r.r_reason_sk = wr.wr_reason_sk
  LEFT   JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
  LEFT   JOIN tpcds.warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk
  LEFT   JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
  LEFT   JOIN tpcds.promotion p ON p.p_promo_sk = ws.ws_promo_sk
  LEFT   JOIN tpcds.web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
  LEFT   JOIN tpcds.web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
  WHERE  d.d_year = 2001
    AND  p.p_discount_active = 'Y'
    AND  ws.ws_quantity > 0
    AND  ws.ws_sales_price > 10
    AND  ws.ws_ext_tax > 0
    AND  sm.sm_type = 'AIR'
    AND  w.w_state = 'CA'
    AND  r.r_reason_desc LIKE '%late%'
  GROUP BY d.d_year, d.d_month_seq
  HAVING SUM(ws.ws_ext_sales_price) > 9000
),
combined AS (
  SELECT 'Catalog' AS channel, d_year, d_month_seq, sales_amount, metric_cnt
  FROM   catalog_agg
  UNION ALL
  SELECT 'Store'   AS channel, d_year, d_month_seq, sales_amount, metric_cnt
  FROM   store_agg
  UNION ALL
  SELECT 'Web'     AS channel, d_year, d_month_seq, sales_amount, metric_cnt
  FROM   web_agg
),
ranked AS (
  SELECT channel,
         d_year,
         d_month_seq,
         sales_amount,
         metric_cnt,
         ROW_NUMBER() OVER (PARTITION BY channel ORDER BY sales_amount DESC) AS rn
  FROM   combined
)
SELECT channel,
       d_year,
       d_month_seq,
       sales_amount,
       metric_cnt
FROM   ranked
WHERE  rn <= 5
ORDER BY channel, sales_amount DESC
LIMIT 100
