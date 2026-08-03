WITH
  combined AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      ss.ss_sold_date_sk            AS sold_date_sk,
      ss.ss_ext_sales_price          AS sales_amount,
      CAST('store' AS VARCHAR)       AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
    UNION ALL
    SELECT
      i.i_item_sk,
      i.i_product_name,
      ws.ws_sold_date_sk            AS sold_date_sk,
      ws.ws_ext_sales_price          AS sales_amount,
      CAST('web'   AS VARCHAR)       AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
  ),
  agg AS (
    SELECT
      i_item_sk,
      i_product_name,
      channel,
      SUM(sales_amount)               AS total_sales,
      MIN(sold_date_sk)               AS first_date
    FROM combined
    GROUP BY GROUPING SETS (
      (i_item_sk, i_product_name, channel),
      (i_item_sk, i_product_name)
    )
    HAVING SUM(sales_amount) > 0
  )
SELECT
  i_item_sk,
  i_product_name,
  channel,
  total_sales,
  CASE WHEN channel = 'store' THEN 'In-Store' ELSE 'Online' END AS channel_desc,
  LAG(total_sales) OVER (PARTITION BY i_item_sk ORDER BY first_date)          AS prev_total_sales,
  SUM(total_sales) OVER (PARTITION BY i_item_sk ORDER BY first_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM agg
ORDER BY i_item_sk, channel
LIMIT 100
