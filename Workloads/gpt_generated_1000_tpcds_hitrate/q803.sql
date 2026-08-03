WITH
  store_base AS (
    SELECT
      d.d_date            AS sales_date,
      ss.ss_item_sk       AS item_sk,
      SUM(ss.ss_net_profit)      AS net_profit,
      SUM(ss.ss_quantity)         AS quantity,
      SUM(ss.ss_ext_sales_price) AS sales_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, ss.ss_item_sk
  ),
  catalog_base AS (
    SELECT
      d.d_date            AS sales_date,
      cs.cs_item_sk       AS item_sk,
      SUM(cs.cs_net_profit)      AS net_profit,
      SUM(cs.cs_quantity)         AS quantity,
      SUM(cs.cs_ext_sales_price) AS sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, cs.cs_item_sk
  ),
  intersected AS (
    SELECT sales_date, item_sk, net_profit, quantity, sales_amount
    FROM store_base
    INTERSECT
    SELECT sales_date, item_sk, net_profit, quantity, sales_amount
    FROM catalog_base
  ),
  with_window AS (
    SELECT
      sales_date,
      item_sk,
      net_profit,
      quantity,
      sales_amount,
      LAG(net_profit) OVER (PARTITION BY item_sk ORDER BY sales_date) AS prev_day_profit,
      SUM(net_profit) OVER (PARTITION BY item_sk ORDER BY sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit
    FROM intersected
  )
SELECT
  sales_date,
  item_sk,
  SUM(net_profit)        AS total_net_profit,
  SUM(quantity)          AS total_quantity,
  SUM(sales_amount)      AS total_sales_amount,
  SUM(prev_day_profit)   AS sum_prev_day_profit,
  SUM(running_profit)    AS sum_running_profit
FROM with_window
GROUP BY GROUPING SETS ((sales_date, item_sk), (sales_date), (item_sk), ())
ORDER BY sales_date, item_sk
