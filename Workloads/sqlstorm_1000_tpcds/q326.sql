WITH
sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    s.channel,
    SUM(s.quantity) AS total_qty,
    SUM(s.net_paid) AS total_sales,
    SUM(s.net_profit) AS total_profit
  FROM (
    SELECT
      ws.ws_sold_date_sk AS date_sk,
      ws.ws_item_sk AS item_sk,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid AS net_paid,
      ws.ws_net_profit AS net_profit,
      'web' AS channel
    FROM web_sales ws
    UNION ALL
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      'catalog'
    FROM catalog_sales cs
    UNION ALL
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      'store'
    FROM store_sales ss
  ) s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY
    d.d_year,
    i.i_category,
    i.i_brand,
    s.channel
),
returns_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    r.channel,
    SUM(r.return_quantity) AS total_ret_qty,
    SUM(r.return_amount) AS total_ret_amount,
    SUM(r.net_loss) AS total_ret_loss
  FROM (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_item_sk AS item_sk,
      cr.cr_return_quantity AS return_quantity,
      cr.cr_return_amount AS return_amount,
      cr.cr_net_loss AS net_loss,
      'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      'store'
    FROM store_returns sr
    UNION ALL
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      'web'
    FROM web_returns wr
  ) r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  JOIN item i ON r.item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY
    d.d_year,
    i.i_category,
    i.i_brand,
    r.channel
)
SELECT
  COALESCE(s.d_year, r.d_year) AS sales_year,
  COALESCE(s.i_category, r.i_category) AS category,
  COALESCE(s.i_brand, r.i_brand) AS brand,
  COALESCE(s.channel, r.channel) AS channel,
  COALESCE(s.total_qty, 0) AS total_qty_sold,
  COALESCE(s.total_sales, 0) AS total_sales,
  COALESCE(s.total_profit, 0) AS total_profit,
  COALESCE(r.total_ret_qty, 0) AS total_qty_returned,
  COALESCE(r.total_ret_amount, 0) AS total_return_amount,
  COALESCE(r.total_ret_loss, 0) AS total_return_loss,
  COALESCE(s.total_sales, 0) - COALESCE(r.total_ret_amount, 0) AS net_sales,
  COALESCE(s.total_profit, 0) - COALESCE(r.total_ret_loss, 0) AS net_profit,
  ROW_NUMBER() OVER (
    PARTITION BY COALESCE(s.i_category, r.i_category)
    ORDER BY COALESCE(s.total_profit, 0) - COALESCE(r.total_ret_loss, 0) DESC
  ) AS brand_profit_rank
FROM sales_agg s
FULL OUTER JOIN returns_agg r
  ON s.d_year = r.d_year
  AND s.i_category = r.i_category
  AND s.i_brand = r.i_brand
  AND s.channel = r.channel
WHERE COALESCE(s.total_qty, 0) > 0 OR COALESCE(r.total_ret_qty, 0) > 0
ORDER BY sales_year, category, net_profit DESC
