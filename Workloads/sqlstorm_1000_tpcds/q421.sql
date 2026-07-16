WITH store_sales_agg AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_store_sk AS store_sk,
           ss_item_sk AS item_sk,
           SUM(ss_net_paid) AS total_sales,
           SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_store_sk, ss_item_sk
),
store_returns_agg AS (
    SELECT sr_returned_date_sk AS date_sk,
           sr_store_sk AS store_sk,
           sr_item_sk AS item_sk,
           SUM(sr_return_amt) AS total_returns
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_store_sk, sr_item_sk
),
catalog_sales_agg AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           SUM(cs_ext_sales_price) AS total_catalog_sales
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
),
catalog_returns_agg AS (
    SELECT cr_returned_date_sk AS date_sk,
           cr_item_sk AS item_sk,
           SUM(cr_return_amount) AS total_catalog_returns
    FROM catalog_returns
    GROUP BY cr_returned_date_sk, cr_item_sk
),
web_sales_agg AS (
    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           SUM(ws_ext_sales_price) AS total_web_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
web_returns_agg AS (
    SELECT wr_returned_date_sk AS date_sk,
           wr_item_sk AS item_sk,
           SUM(wr_return_amt) AS total_web_returns
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_item_sk
)
SELECT d.d_year,
       d.d_month_seq,
       i.i_category,
       i.i_brand,
       s.s_store_name,
       COALESCE(ss.total_sales, 0) AS store_sales,
       COALESCE(ss.total_profit, 0) AS store_profit,
       COALESCE(sr.total_returns, 0) AS store_returns,
       COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
       COALESCE(cr.total_catalog_returns, 0) AS catalog_returns,
       COALESCE(ws.total_web_sales, 0) AS web_sales,
       COALESCE(wr.total_web_returns, 0) AS web_returns
FROM store_sales_agg ss
JOIN date_dim d ON d.d_date_sk = ss.date_sk
JOIN store s ON s.s_store_sk = ss.store_sk
LEFT JOIN store_returns_agg sr ON sr.date_sk = ss.date_sk AND sr.store_sk = ss.store_sk AND sr.item_sk = ss.item_sk
LEFT JOIN item i ON i.i_item_sk = ss.item_sk
LEFT JOIN catalog_sales_agg cs ON cs.date_sk = ss.date_sk AND cs.item_sk = ss.item_sk
LEFT JOIN catalog_returns_agg cr ON cr.date_sk = ss.date_sk AND cr.item_sk = ss.item_sk
LEFT JOIN web_sales_agg ws ON ws.date_sk = ss.date_sk AND ws.item_sk = ss.item_sk
LEFT JOIN web_returns_agg wr ON wr.date_sk = ss.date_sk AND wr.item_sk = ss.item_sk
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
ORDER BY store_sales DESC
LIMIT 100
