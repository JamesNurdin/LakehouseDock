WITH
date_filtered AS (
  SELECT d_date_sk, d_year, d_month_seq
  FROM date_dim
  WHERE d_year BETWEEN 2001 AND 2002
),
catalog_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cs.cs_item_sk AS item_sk,
    i.i_product_name,
    sum(cs.cs_net_paid_inc_ship_tax) AS sales_amount,
    sum(cs.cs_net_profit) AS profit,
    sum(cs.cs_quantity) AS qty_sold,
    min(cs.cs_promo_sk) AS promo_sk
  FROM catalog_sales cs
  JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, cs.cs_item_sk, i.i_product_name
),
catalog_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cr.cr_item_sk AS item_sk,
    sum(cr.cr_net_loss) AS loss,
    sum(cr.cr_return_quantity) AS qty_returned
  FROM catalog_returns cr
  JOIN date_filtered d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, cr.cr_item_sk
),
catalog_combined AS (
  SELECT
    cs.d_year,
    cs.d_month_seq,
    cs.item_sk,
    cs.i_product_name,
    cs.sales_amount,
    cs.profit - coalesce(cr.loss, 0) AS profit_adj,
    cs.qty_sold,
    coalesce(cr.qty_returned, 0) AS qty_returned,
    cs.promo_sk
  FROM catalog_sales_agg cs
  LEFT JOIN catalog_returns_agg cr
    ON cs.item_sk = cr.item_sk
   AND cs.d_year = cr.d_year
   AND cs.d_month_seq = cr.d_month_seq
),
store_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    ss.ss_item_sk AS item_sk,
    i.i_product_name,
    sum(ss.ss_net_paid_inc_tax) AS sales_amount,
    sum(ss.ss_net_profit) AS profit,
    sum(ss.ss_quantity) AS qty_sold,
    min(ss.ss_promo_sk) AS promo_sk
  FROM store_sales ss
  JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, ss.ss_item_sk, i.i_product_name
),
store_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    sr.sr_item_sk AS item_sk,
    sum(sr.sr_net_loss) AS loss,
    sum(sr.sr_return_quantity) AS qty_returned
  FROM store_returns sr
  JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, sr.sr_item_sk
),
store_combined AS (
  SELECT
    ss.d_year,
    ss.d_month_seq,
    ss.item_sk,
    ss.i_product_name,
    ss.sales_amount,
    ss.profit - coalesce(sr.loss, 0) AS profit_adj,
    ss.qty_sold,
    coalesce(sr.qty_returned, 0) AS qty_returned,
    ss.promo_sk
  FROM store_sales_agg ss
  LEFT JOIN store_returns_agg sr
    ON ss.item_sk = sr.item_sk
   AND ss.d_year = sr.d_year
   AND ss.d_month_seq = sr.d_month_seq
),
web_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    ws.ws_item_sk AS item_sk,
    i.i_product_name,
    sum(ws.ws_net_paid_inc_ship_tax) AS sales_amount,
    sum(ws.ws_net_profit) AS profit,
    sum(ws.ws_quantity) AS qty_sold,
    min(ws.ws_promo_sk) AS promo_sk
  FROM web_sales ws
  JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, ws.ws_item_sk, i.i_product_name
),
web_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    wr.wr_item_sk AS item_sk,
    sum(wr.wr_net_loss) AS loss,
    sum(wr.wr_return_quantity) AS qty_returned
  FROM web_returns wr
  JOIN date_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, wr.wr_item_sk
),
web_combined AS (
  SELECT
    ws.d_year,
    ws.d_month_seq,
    ws.item_sk,
    ws.i_product_name,
    ws.sales_amount,
    ws.profit - coalesce(wr.loss, 0) AS profit_adj,
    ws.qty_sold,
    coalesce(wr.qty_returned, 0) AS qty_returned,
    ws.promo_sk
  FROM web_sales_agg ws
  LEFT JOIN web_returns_agg wr
    ON ws.item_sk = wr.item_sk
   AND ws.d_year = wr.d_year
   AND ws.d_month_seq = wr.d_month_seq
),
all_channels AS (
  SELECT * FROM catalog_combined
  UNION ALL
  SELECT * FROM store_combined
  UNION ALL
  SELECT * FROM web_combined
),
monthly_item_agg AS (
  SELECT
    d_year,
    d_month_seq,
    item_sk,
    i_product_name,
    sum(sales_amount) AS total_sales,
    sum(profit_adj) AS total_profit,
    sum(qty_sold) AS total_qty_sold,
    sum(qty_returned) AS total_qty_returned,
    min(promo_sk) AS promo_sk
  FROM all_channels
  GROUP BY d_year, d_month_seq, item_sk, i_product_name
),
ranked_items AS (
  SELECT
    d_year,
    d_month_seq,
    item_sk,
    i_product_name,
    total_sales,
    total_profit,
    total_qty_sold,
    total_qty_returned,
    promo_sk,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank,
    AVG(total_profit) OVER (PARTITION BY d_year ORDER BY d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3month_moving_avg
  FROM monthly_item_agg
)
SELECT
  d_year,
  d_month_seq,
  item_sk,
  i_product_name,
  total_sales,
  total_profit,
  total_qty_sold,
  total_qty_returned,
  profit_rank,
  profit_3month_moving_avg
FROM ranked_items
WHERE profit_rank <= 10
ORDER BY d_year, d_month_seq, profit_rank
