WITH
  /* Aggregate store sales for 2022, exclude items that were returned on the same year */
  store_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      (
        SELECT AVG(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
      ) AS avg_sales_per_tx
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
      AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
        WHERE wr.wr_item_sk = i.i_item_sk
          AND dr.d_year = 2022
      )
    GROUP BY i.i_item_sk, i.i_item_id
  ),
  store_sales_ranked AS (
    SELECT
      i_item_id,
      total_sales,
      avg_sales_per_tx,
      ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM store_sales_agg
  ),
  /* Aggregate web sales for 2022 */
  web_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
      ) AS avg_sales_per_tx
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_item_sk, i.i_item_id
  ),
  web_sales_ranked AS (
    SELECT
      i_item_id,
      total_sales,
      avg_sales_per_tx,
      ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM web_sales_agg
  )
SELECT *
FROM (
  SELECT
    'store' AS channel,
    s.i_item_id,
    s.total_sales,
    s.avg_sales_per_tx,
    s.sales_rank
  FROM store_sales_ranked s

  UNION ALL

  SELECT
    'web' AS channel,
    w.i_item_id,
    w.total_sales,
    w.avg_sales_per_tx,
    w.sales_rank
  FROM web_sales_ranked w
) combined
ORDER BY total_sales DESC
LIMIT 100
