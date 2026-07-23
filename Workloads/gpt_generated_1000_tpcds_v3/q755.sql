WITH filtered_date AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year = 2001
),
high_income AS (
    SELECT ib_income_band_sk
    FROM income_band
    WHERE ib_lower_bound >= 40000
)
SELECT
    s.s_store_name,
    d.d_date,
    sm.sm_type,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_txn,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_txn,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_txn,
    SUM(cr.cr_net_loss) AS total_return_loss,
    AVG(ss.ss_sales_price) AS avg_store_price,
    MAX(ws.ws_sales_price) AS max_web_price,
    MIN(cr.cr_return_amount) AS min_return_amount,
    (
        SELECT AVG(ss2.ss_net_paid_inc_tax)
        FROM store_sales ss2
        JOIN filtered_date d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS avg_store_sales_per_store
FROM filtered_date d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN high_income hi ON hd.hd_income_band_sk = hi.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
WHERE s.s_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND EXISTS (
      SELECT 1
      FROM web_sales ws2
      WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
        AND ws2.ws_net_paid_inc_tax > 1000
        AND ws2.ws_sold_date_sk = d.d_date_sk
  )
GROUP BY s.s_store_name, d.d_date, sm.sm_type, s.s_store_sk
ORDER BY total_store_sales DESC
LIMIT 100
