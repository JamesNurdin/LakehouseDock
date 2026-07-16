WITH sales AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_quantity) AS quantity,
    SUM(cs.cs_ext_sales_price) AS ext_sales,
    SUM(cs.cs_ext_discount_amt) AS discount,
    SUM(p.p_cost) AS promo_cost
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY d.d_year, d.d_month_seq
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_quantity) AS quantity,
    SUM(ss.ss_ext_sales_price) AS ext_sales,
    SUM(ss.ss_ext_discount_amt) AS discount,
    SUM(p.p_cost) AS promo_cost
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  GROUP BY d.d_year, d.d_month_seq
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_quantity) AS quantity,
    SUM(ws.ws_ext_sales_price) AS ext_sales,
    SUM(ws.ws_ext_discount_amt) AS discount,
    SUM(p.p_cost) AS promo_cost
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY d.d_year, d.d_month_seq
),
returns AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    SUM(cr.cr_net_loss) AS net_loss,
    SUM(cr.cr_return_quantity) AS return_qty
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    SUM(sr.sr_net_loss) AS net_loss,
    SUM(sr.sr_return_quantity) AS return_qty
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    SUM(wr.wr_net_loss) AS net_loss,
    SUM(wr.wr_return_quantity) AS return_qty
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq
),
combined AS (
  SELECT
    s.d_year,
    s.d_month_seq,
    s.channel,
    s.net_profit,
    s.quantity,
    s.ext_sales,
    s.discount,
    s.promo_cost,
    COALESCE(r.net_loss, 0) AS net_loss,
    COALESCE(r.return_qty, 0) AS return_qty
  FROM sales s
  LEFT JOIN returns r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.channel = r.channel
),
aggregated AS (
  SELECT
    d_year,
    d_month_seq,
    channel,
    SUM(net_profit) AS total_net_profit,
    SUM(net_loss) AS total_net_loss,
    SUM(ext_sales) AS total_ext_sales,
    SUM(discount) AS total_discount,
    SUM(promo_cost) AS total_promo_cost,
    SUM(quantity) AS total_quantity,
    SUM(return_qty) AS total_return_qty,
    SUM(net_profit) - SUM(net_loss) AS net_contribution
  FROM combined
  GROUP BY d_year, d_month_seq, channel
  HAVING SUM(ext_sales) > 10000
)
SELECT
  d_year,
  d_month_seq,
  channel,
  total_net_profit,
  total_net_loss,
  net_contribution,
  total_ext_sales,
  total_discount,
  total_promo_cost,
  total_quantity,
  total_return_qty,
  ROUND(100.0 * total_net_profit / NULLIF(total_ext_sales, 0), 2) AS profit_margin_pct,
  ROUND(100.0 * total_return_qty / NULLIF(total_quantity, 0), 2) AS return_rate_pct,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_contribution DESC) AS rank_by_contribution
FROM aggregated
ORDER BY d_year DESC, d_month_seq DESC, channel
