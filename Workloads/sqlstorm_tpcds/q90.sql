WITH
sales_data AS (
  SELECT cs.cs_item_sk AS item_sk,
         cs.cs_sold_date_sk AS date_sk,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk IS NOT NULL
  UNION ALL
  SELECT ss.ss_item_sk,
         ss.ss_sold_date_sk,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         'store'
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk IS NOT NULL
  UNION ALL
  SELECT ws.ws_item_sk,
         ws.ws_sold_date_sk,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         'web'
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk IS NOT NULL
),
returns_data AS (
  SELECT cr.cr_item_sk AS item_sk,
         cr.cr_returned_date_sk AS date_sk,
         cr.cr_return_quantity AS quantity,
         cr.cr_net_loss AS net_loss,
         'catalog' AS channel
  FROM catalog_returns cr
  WHERE cr.cr_returned_date_sk IS NOT NULL
  UNION ALL
  SELECT sr.sr_item_sk,
         sr.sr_returned_date_sk,
         sr.sr_return_quantity,
         sr.sr_net_loss,
         'store'
  FROM store_returns sr
  WHERE sr.sr_returned_date_sk IS NOT NULL
  UNION ALL
  SELECT wr.wr_item_sk,
         wr.wr_returned_date_sk,
         wr.wr_return_quantity,
         wr.wr_net_loss,
         'web'
  FROM web_returns wr
  WHERE wr.wr_returned_date_sk IS NOT NULL
),
sales_agg AS (
  SELECT
    s.item_sk,
    s.channel,
    d.d_year,
    d.d_month_seq,
    SUM(s.quantity) AS total_quantity,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit
  FROM sales_data s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY s.item_sk, s.channel, d.d_year, d.d_month_seq
),
returns_agg AS (
  SELECT
    r.item_sk,
    r.channel,
    d.d_year,
    d.d_month_seq,
    SUM(r.quantity) AS total_return_quantity,
    SUM(r.net_loss) AS total_return_loss
  FROM returns_data r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY r.item_sk, r.channel, d.d_year, d.d_month_seq
),
ranked AS (
  SELECT
    sa.d_year,
    sa.d_month_seq,
    sa.channel,
    i.i_category,
    i.i_class,
    i.i_brand,
    i.i_color,
    i.i_size,
    sa.total_quantity,
    sa.total_net_paid,
    sa.total_net_profit,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    CASE WHEN sa.total_net_paid > 0 THEN COALESCE(ra.total_return_loss, 0) / sa.total_net_paid ELSE 0 END AS return_loss_ratio,
    RANK() OVER (PARTITION BY sa.d_year, sa.d_month_seq, sa.channel ORDER BY sa.total_net_profit DESC) AS profit_rank
  FROM sales_agg sa
  JOIN item i ON sa.item_sk = i.i_item_sk
  LEFT JOIN returns_agg ra
    ON sa.item_sk = ra.item_sk
   AND sa.channel = ra.channel
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
  WHERE sa.total_net_profit > 0
)
SELECT
  d_year,
  d_month_seq,
  channel,
  i_category,
  i_class,
  i_brand,
  i_color,
  i_size,
  total_quantity,
  total_net_paid,
  total_net_profit,
  total_return_quantity,
  total_return_loss,
  return_loss_ratio,
  profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, d_month_seq, channel, profit_rank
