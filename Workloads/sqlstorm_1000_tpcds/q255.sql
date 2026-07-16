WITH store_sales_agg AS (
  SELECT
    d.d_year,
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_net_paid) AS store_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn
  FROM date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND s.s_state = 'CA'
  GROUP BY d.d_year, s.s_store_name, i.i_category
),
store_returns_agg AS (
  SELECT
    d.d_year,
    s.s_store_name,
    i.i_category,
    SUM(sr.sr_net_loss) AS store_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_txn
  FROM date_dim d
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND s.s_state = 'CA'
  GROUP BY d.d_year, s.s_store_name, i.i_category
),
catalog_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(cs.cs_net_paid) AS catalog_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_txn
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, i.i_category
),
catalog_returns_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(cr.cr_net_loss) AS catalog_returns,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_txn
  FROM date_dim d
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, i.i_category
),
web_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(ws.ws_net_paid) AS web_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_txn
  FROM date_dim d
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, i.i_category
),
web_returns_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(wr.wr_net_loss) AS web_returns,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_txn
  FROM date_dim d
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, i.i_category
),
combined AS (
  SELECT
    ss.d_year,
    ss.s_store_name,
    ss.i_category,
    ss.store_sales,
    COALESCE(sr.store_returns, 0) AS store_returns,
    COALESCE(cs.catalog_sales, 0) AS catalog_sales,
    COALESCE(cr.catalog_returns, 0) AS catalog_returns,
    COALESCE(ws.web_sales, 0) AS web_sales,
    COALESCE(wr.web_returns, 0) AS web_returns,
    ss.store_txn,
    COALESCE(sr.return_txn, 0) AS return_txn,
    COALESCE(cs.catalog_txn, 0) AS catalog_txn,
    COALESCE(cr.catalog_return_txn, 0) AS catalog_return_txn,
    COALESCE(ws.web_txn, 0) AS web_txn,
    COALESCE(wr.web_return_txn, 0) AS web_return_txn,
    (ss.store_sales + COALESCE(cs.catalog_sales, 0) + COALESCE(ws.web_sales, 0) -
     COALESCE(sr.store_returns, 0) - COALESCE(cr.catalog_returns, 0) - COALESCE(wr.web_returns, 0)) AS net_sales
  FROM store_sales_agg ss
  LEFT JOIN store_returns_agg sr
    ON sr.d_year = ss.d_year
   AND sr.s_store_name = ss.s_store_name
   AND sr.i_category = ss.i_category
  LEFT JOIN catalog_sales_agg cs
    ON cs.d_year = ss.d_year
   AND cs.i_category = ss.i_category
  LEFT JOIN catalog_returns_agg cr
    ON cr.d_year = ss.d_year
   AND cr.i_category = ss.i_category
  LEFT JOIN web_sales_agg ws
    ON ws.d_year = ss.d_year
   AND ws.i_category = ss.i_category
  LEFT JOIN web_returns_agg wr
    ON wr.d_year = ss.d_year
   AND wr.i_category = ss.i_category
)
SELECT
  d_year,
  s_store_name,
  i_category,
  store_sales,
  store_returns,
  catalog_sales,
  catalog_returns,
  web_sales,
  web_returns,
  net_sales,
  store_txn,
  return_txn,
  catalog_txn,
  catalog_return_txn,
  web_txn,
  web_return_txn
FROM (
  SELECT
    c.*,
    ROW_NUMBER() OVER (PARTITION BY c.d_year, c.s_store_name ORDER BY c.net_sales DESC) AS rn
  FROM combined c
) t
WHERE rn <= 5
ORDER BY d_year, s_store_name, net_sales DESC
LIMIT 20
