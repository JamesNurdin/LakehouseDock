WITH sales_all AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    s.ss_quantity AS quantity,
    s.ss_ext_sales_price AS gross_sales,
    s.ss_net_paid AS net_paid,
    s.ss_net_profit AS net_profit,
    s.ss_promo_sk AS promo_sk
  FROM store_sales s
  JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON s.ss_item_sk = i.i_item_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS gross_sales,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    ws.ws_quantity AS quantity,
    ws.ws_ext_sales_price AS gross_sales,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    ws.ws_promo_sk AS promo_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
returns_all AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    i.i_item_id,
    SUM(sr.sr_return_quantity) AS return_qty,
    SUM(sr.sr_net_loss) AS return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_item_id

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    i.i_item_id,
    SUM(cr.cr_return_quantity) AS return_qty,
    SUM(cr.cr_net_loss) AS return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_item_id

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    i.i_item_id,
    SUM(wr.wr_return_quantity) AS return_qty,
    SUM(wr.wr_net_loss) AS return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_item_id
),
agg AS (
  SELECT
    s.d_year,
    s.d_month_seq,
    s.channel,
    s.i_category,
    s.i_brand,
    s.i_item_id,
    SUM(s.quantity) AS total_quantity,
    SUM(s.gross_sales) AS total_gross_sales,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit,
    SUM(COALESCE(r.return_qty, 0)) AS total_return_qty,
    SUM(COALESCE(r.return_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT s.promo_sk) AS distinct_promotions
  FROM sales_all s
  LEFT JOIN returns_all r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.channel = r.channel
    AND s.i_item_id = r.i_item_id
  GROUP BY GROUPING SETS (
    (s.d_year, s.d_month_seq, s.channel, s.i_category, s.i_brand, s.i_item_id),
    (s.d_year, s.d_month_seq, s.channel, s.i_category, s.i_brand),
    (s.d_year, s.d_month_seq, s.channel)
  )
)
SELECT
  d_year,
  d_month_seq,
  channel,
  COALESCE(i_category, 'ALL') AS category,
  COALESCE(i_brand, 'ALL') AS brand,
  COALESCE(i_item_id, 'ALL') AS item_id,
  total_quantity,
  total_gross_sales,
  total_net_paid,
  (total_net_profit - total_return_loss) AS total_net_profit_adj,
  total_return_qty,
  (total_net_profit - total_return_loss) / NULLIF(total_gross_sales, 0) AS profit_margin,
  distinct_promotions,
  ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY (total_net_profit - total_return_loss) DESC) AS profit_rank
FROM agg
ORDER BY d_year, d_month_seq, channel, profit_rank
LIMIT 200
