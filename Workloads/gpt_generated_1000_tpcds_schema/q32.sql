WITH date_common AS (
   SELECT d_date_sk FROM date_dim
   WHERE d_year = 2002 AND d_moy = 7
   INTERSECT
   SELECT d_date_sk FROM date_dim
   WHERE d_day_name = 'Monday' AND d_holiday = 'N'
)
SELECT
    d.d_year,
    s.s_city,
    w.w_state,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    SUM(sr.sr_return_amt) AS sum_store_return,
    SUM(ws.ws_ext_sales_price) AS sum_sales,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
FROM date_dim d
JOIN date_common dc ON d.d_date_sk = dc.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
WHERE s.s_city = 'Glendale'
  AND site.web_market_manager = 'William Reyes'
  AND w.w_state = 'CA'
GROUP BY d.d_year, s.s_city, w.w_state
ORDER BY sum_sales DESC
