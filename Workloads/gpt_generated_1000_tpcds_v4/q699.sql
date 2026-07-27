SELECT
  web_site_id,
  web_name,
  metric_type,
  metric_amount
FROM (
  SELECT
    site.web_site_id,
    site.web_name,
    'sales' AS metric_type,
    SUM(ws.ws_ext_sales_price) AS metric_amount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  WHERE d.d_year = 2001
  GROUP BY site.web_site_id, site.web_name

  UNION ALL

  SELECT
    site.web_site_id,
    site.web_name,
    'returns' AS metric_type,
    SUM(wr.wr_return_amt) AS metric_amount
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  WHERE d.d_year = 2001
  GROUP BY site.web_site_id, site.web_name
) AS combined
ORDER BY metric_amount DESC
LIMIT 100
