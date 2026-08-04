WITH sales_union AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    ss.ss_store_sk AS store_sk,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2 WHERE ss2.ss_store_sk = ss.ss_store_sk) AS avg_store_profit
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE s.s_country = 'United States'
    AND ss.ss_ext_tax > 50
  UNION ALL
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_web_site_sk AS store_sk,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (SELECT avg(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk) AS avg_store_profit
  FROM web_sales ws
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE w.web_country = 'United States'
    AND ws.ws_ext_tax > 50
),
returns_set AS (
  SELECT
    wr.wr_refunded_customer_sk AS customer_sk,
    ws.ws_web_site_sk AS store_sk,
    'Returned' AS profit_flag,
    CAST(NULL AS double) AS avg_store_profit
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
)
SELECT *
FROM sales_union
EXCEPT
SELECT *
FROM returns_set
ORDER BY profit_flag DESC, customer_sk
OFFSET 0 LIMIT 100
