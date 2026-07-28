WITH filtered_date AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 1999
      AND d_quarter_seq = 12
      AND d_month_seq = 7
)
SELECT
    d.d_year,
    d.d_quarter_seq,
    w.w_warehouse_name,
    c.c_customer_id,
    wsit.web_name,
    r.r_reason_desc,
    SUM(ss.ss_net_paid)                         AS total_store_net_paid,
    SUM(ws.ws_net_paid)                         AS total_web_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number)         AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number)          AS web_transactions,
    CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
    MIN(ss.ss_quantity)                         AS min_store_qty,
    MAX(ws.ws_quantity)                         AS max_web_qty
FROM filtered_date d
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
 AND wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
 AND wsit.web_open_date_sk = d.d_date_sk
WHERE cp.cp_department = 'Electronics'
  AND wp.wp_image_count >= 5
  AND hd.hd_vehicle_count <= 2
  AND ib.ib_lower_bound >= 50000
  AND ws.ws_quantity > 2
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    w.w_warehouse_name,
    c.c_customer_id,
    wsit.web_name,
    r.r_reason_desc
LIMIT 100
