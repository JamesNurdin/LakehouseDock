WITH sales_union AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'store' AS channel,
    COALESCE(st.s_state, 'UNKNOWN') AS region,
    ss.ss_quantity AS quantity,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store st ON ss.ss_store_sk = st.s_store_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'catalog' AS channel,
    COALESCE(cc.cc_state, 'UNKNOWN') AS region,
    cs.cs_quantity AS quantity,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'web' AS channel,
    'WEB' AS region,
    ws.ws_quantity AS quantity,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_discount_amt AS discount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
),
returns_union AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'store' AS channel,
    COALESCE(st.s_state, 'UNKNOWN') AS region,
    sr.sr_return_quantity AS quantity,
    sr.sr_net_loss AS net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store st ON sr.sr_store_sk = st.s_store_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'catalog' AS channel,
    COALESCE(cc.cc_state, 'UNKNOWN') AS region,
    cr.cr_return_quantity AS quantity,
    cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'web' AS channel,
    'WEB' AS region,
    wr.wr_return_quantity AS quantity,
    wr.wr_net_loss AS net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
),
agg AS (
  SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.channel,
    s.region,
    SUM(s.quantity) AS total_quantity,
    SUM(s.net_profit) AS total_net_profit,
    SUM(s.discount) AS total_discount,
    SUM(COALESCE(r.net_loss, 0)) AS total_return_loss,
    SUM(s.net_profit) - SUM(COALESCE(r.net_loss, 0)) AS net_profit_after_returns
  FROM sales_union s
  LEFT JOIN returns_union r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
   AND s.channel = r.channel
   AND s.region = r.region
  GROUP BY s.d_year, s.d_month_seq, s.i_category, s.channel, s.region
)
SELECT
  d_year,
  d_month_seq,
  i_category,
  channel,
  region,
  total_quantity,
  total_net_profit,
  total_discount,
  total_return_loss,
  net_profit_after_returns,
  ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM agg
ORDER BY d_year, d_month_seq, channel, profit_rank
LIMIT 200
