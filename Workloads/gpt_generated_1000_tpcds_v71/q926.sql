WITH agg1 AS (
    SELECT
        s.s_store_name,
        we.web_name,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(wr.wr_return_amt) AS total_web_returns
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE ss.ss_ext_tax > 20
      AND cr.cr_return_amount > 100
      AND we.web_zip = '49532'
      AND w.w_city = 'Lincoln'
      AND r.r_reason_desc = 'Damaged'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY s.s_store_name, we.web_name
)
SELECT
    a.s_store_name,
    a.web_name,
    a.total_store_sales,
    a.total_web_sales,
    a.total_catalog_returns,
    a.total_web_returns,
    (a.total_store_sales - a.total_catalog_returns) AS net_store_gain,
    (a.total_web_sales - a.total_web_returns) AS net_web_gain,
    ((a.total_store_sales - a.total_catalog_returns) + (a.total_web_sales - a.total_web_returns)) / 2.0 AS avg_net_gain
FROM agg1 a
WHERE a.total_store_sales > (SELECT AVG(total_store_sales) FROM agg1)
  AND a.total_web_sales > 0
ORDER BY avg_net_gain DESC
LIMIT 100
