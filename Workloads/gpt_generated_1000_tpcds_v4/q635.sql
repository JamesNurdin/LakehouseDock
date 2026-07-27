WITH ws_wr AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    ws.ws_ship_mode_sk,
    ws.ws_warehouse_sk,
    ws.ws_web_site_sk,
    ca.ca_city,
    ca.ca_state,
    ws.ws_sold_date_sk,
    wr.wr_return_amt_inc_tax,
    wr.wr_return_quantity,
    wr.wr_return_tax
  FROM tpcds.web_sales ws
  JOIN tpcds.web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  JOIN tpcds.customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_city, '^A')
)
SELECT
  ws_wr.ws_web_site_sk,
  ws_site.web_name,
  ws_site.web_county,
  regexp_extract(ws_site.web_site_id, '\\d+', 0) AS site_id_digits,
  COUNT(DISTINCT ws_wr.ws_order_number) AS orders,
  SUM(ws_wr.ws_net_paid) AS total_sales,
  SUM(ws_wr.wr_return_amt_inc_tax) AS total_returns,
  ROUND(SUM(ws_wr.wr_return_amt_inc_tax) / NULLIF(SUM(ws_wr.ws_net_paid), 0) * 100, 2) AS return_rate_percent,
  MIN(ws_wr.ca_city) AS sample_city
FROM ws_wr
JOIN tpcds.web_site ws_site
  ON ws_wr.ws_web_site_sk = ws_site.web_site_sk
WHERE ws_site.web_name LIKE '%Shop%'
  AND regexp_like(ws_site.web_county, 'County$')
GROUP BY
  ws_wr.ws_web_site_sk,
  ws_site.web_name,
  ws_site.web_county,
  regexp_extract(ws_site.web_site_id, '\\d+', 0)
ORDER BY total_sales DESC
LIMIT 100
