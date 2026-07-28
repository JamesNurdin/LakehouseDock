WITH store_daily AS (
  SELECT
    d.d_date AS sale_date,
    'store' AS sales_channel,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    )
  GROUP BY d.d_date
),
web_daily AS (
  SELECT
    d.d_date AS sale_date,
    'web' AS sales_channel,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND NOT EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    )
  GROUP BY d.d_date
)
SELECT
  sd.sale_date,
  sd.sales_channel,
  sd.total_net_profit,
  sd.total_quantity,
  sd.avg_discount
FROM store_daily sd
UNION ALL
SELECT
  wd.sale_date,
  wd.sales_channel,
  wd.total_net_profit,
  wd.total_quantity,
  wd.avg_discount
FROM web_daily wd
WHERE wd.sale_date IN (
  SELECT d2.d_date
  FROM date_dim d2
  WHERE d2.d_month_seq BETWEEN 1 AND 12
    AND d2.d_following_holiday = 'N'
)
ORDER BY sale_date DESC
LIMIT 100
