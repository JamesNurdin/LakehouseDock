WITH store_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq AS month,
    i.i_category,
    cd.cd_gender,
    'store' AS channel,
    SUM(ss.ss_quantity) AS sales_qty,
    SUM(ss.ss_net_profit) AS sales_profit,
    SUM(ss.ss_net_paid) AS sales_net_paid,
    SUM(ss.ss_ext_discount_amt) AS sales_discount,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS return_qty,
    COALESCE(SUM(sr.sr_net_loss), 0) AS return_loss,
    COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS return_amount_inc_tax
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
),
catalog_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq AS month,
    i.i_category,
    cd.cd_gender,
    'catalog' AS channel,
    SUM(cs.cs_quantity) AS sales_qty,
    SUM(cs.cs_net_profit) AS sales_profit,
    SUM(cs.cs_net_paid) AS sales_net_paid,
    SUM(cs.cs_ext_discount_amt) AS sales_discount,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS return_qty,
    COALESCE(SUM(cr.cr_net_loss), 0) AS return_loss,
    COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) AS return_amount_inc_tax
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
),
web_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq AS month,
    i.i_category,
    cd.cd_gender,
    'web' AS channel,
    SUM(ws.ws_quantity) AS sales_qty,
    SUM(ws.ws_net_profit) AS sales_profit,
    SUM(ws.ws_net_paid) AS sales_net_paid,
    SUM(ws.ws_ext_discount_amt) AS sales_discount,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS return_qty,
    COALESCE(SUM(wr.wr_net_loss), 0) AS return_loss,
    COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS return_amount_inc_tax
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
),
combined AS (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
),
final AS (
  SELECT
    d_year,
    month,
    channel,
    i_category,
    cd_gender,
    sales_qty,
    return_qty,
    sales_profit,
    return_loss,
    sales_net_paid,
    (sales_qty - return_qty) AS net_qty,
    (sales_profit - return_loss) AS net_profit_adj,
    CASE WHEN sales_qty = 0 THEN 0 ELSE 100.0 * return_qty / sales_qty END AS return_rate_pct,
    CASE WHEN sales_qty = 0 THEN 0 ELSE sales_net_paid / sales_qty END AS avg_net_paid_per_qty,
    ROW_NUMBER() OVER (PARTITION BY d_year, month, channel, cd_gender ORDER BY (sales_profit - return_loss) DESC) AS profit_rank
  FROM combined
)
SELECT
  d_year,
  month,
  channel,
  cd_gender,
  i_category,
  net_qty,
  net_profit_adj,
  return_rate_pct,
  avg_net_paid_per_qty,
  profit_rank
FROM final
WHERE profit_rank <= 5
ORDER BY d_year, month, channel, cd_gender, profit_rank
