WITH sales_agg AS (
  SELECT
    'store' AS channel,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    sum(ss.ss_quantity) AS total_quantity,
    sum(ss.ss_net_profit) AS total_net_profit,
    sum(ss.ss_ext_sales_price) AS total_sales_price,
    sum(ss.ss_ext_discount_amt) AS total_discount,
    sum(ss.ss_coupon_amt) AS total_coupon
  FROM store_sales ss
  GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
  UNION ALL
  SELECT
    'web' AS channel,
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_item_sk AS item_sk,
    sum(ws.ws_quantity) AS total_quantity,
    sum(ws.ws_net_profit) AS total_net_profit,
    sum(ws.ws_ext_sales_price) AS total_sales_price,
    sum(ws.ws_ext_discount_amt) AS total_discount,
    sum(ws.ws_coupon_amt) AS total_coupon
  FROM web_sales ws
  GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
  UNION ALL
  SELECT
    'catalog' AS channel,
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_item_sk AS item_sk,
    sum(cs.cs_quantity) AS total_quantity,
    sum(cs.cs_net_profit) AS total_net_profit,
    sum(cs.cs_ext_sales_price) AS total_sales_price,
    sum(cs.cs_ext_discount_amt) AS total_discount,
    sum(cs.cs_coupon_amt) AS total_coupon
  FROM catalog_sales cs
  GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
),
returns_agg AS (
  SELECT
    'store' AS channel,
    sr.sr_returned_date_sk AS date_sk,
    sr.sr_item_sk AS item_sk,
    sum(sr.sr_return_quantity) AS total_return_quantity,
    sum(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
  UNION ALL
  SELECT
    'web' AS channel,
    wr.wr_returned_date_sk AS date_sk,
    wr.wr_item_sk AS item_sk,
    sum(wr.wr_return_quantity) AS total_return_quantity,
    sum(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
  UNION ALL
  SELECT
    'catalog' AS channel,
    cr.cr_returned_date_sk AS date_sk,
    cr.cr_item_sk AS item_sk,
    sum(cr.cr_return_quantity) AS total_return_quantity,
    sum(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
)
SELECT
  sales_year,
  sales_month_seq,
  channel,
  i_category,
  i_brand,
  i_product_name,
  quantity_sold,
  sales_amount,
  discount_amount,
  net_profit,
  median_net_profit,
  stddev_net_profit,
  quantity_returned,
  return_rate,
  rank() OVER (PARTITION BY sales_year, sales_month_seq, channel ORDER BY net_profit DESC) AS profit_rank
FROM (
  SELECT
    d.d_year AS sales_year,
    d.d_month_seq AS sales_month_seq,
    s.channel,
    i.i_category,
    i.i_brand,
    i.i_product_name,
    sum(s.total_quantity) AS quantity_sold,
    sum(s.total_sales_price) AS sales_amount,
    sum(s.total_discount) AS discount_amount,
    sum(s.total_net_profit) AS net_profit,
    approx_percentile(s.total_net_profit, 0.5) AS median_net_profit,
    stddev(s.total_net_profit) AS stddev_net_profit,
    sum(COALESCE(r.total_return_quantity, 0)) AS quantity_returned,
    CASE WHEN sum(s.total_quantity) = 0 THEN 0
         ELSE sum(COALESCE(r.total_return_quantity, 0)) * 1.0 / sum(s.total_quantity)
    END AS return_rate
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.channel = r.channel
   AND s.item_sk = r.item_sk
   AND s.date_sk = r.date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_month_seq, s.channel, i.i_category, i.i_brand, i.i_product_name
  HAVING sum(s.total_quantity) > 1000
) agg
ORDER BY sales_year, sales_month_seq, channel, profit_rank
LIMIT 100
