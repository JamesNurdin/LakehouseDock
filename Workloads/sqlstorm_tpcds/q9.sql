WITH sales_union AS (
  SELECT ss.ss_sold_date_sk AS sold_date_sk,
         ss.ss_store_sk AS entity_sk,
         ss.ss_net_paid_inc_tax AS net_paid,
         ss.ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT cs.cs_sold_date_sk AS sold_date_sk,
         cs.cs_call_center_sk AS entity_sk,
         cs.cs_net_paid_inc_tax AS net_paid,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ws.ws_sold_date_sk AS sold_date_sk,
         ws.ws_web_page_sk AS entity_sk,
         ws.ws_net_paid_inc_tax AS net_paid,
         ws.ws_net_profit AS net_profit,
         'web' AS channel
  FROM web_sales ws
), returns_union AS (
  SELECT sr.sr_returned_date_sk AS return_date_sk,
         sr.sr_store_sk AS entity_sk,
         sr.sr_return_amt_inc_tax AS return_amt,
         sr.sr_net_loss AS net_loss,
         'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT cr.cr_returned_date_sk AS return_date_sk,
         cr.cr_call_center_sk AS entity_sk,
         cr.cr_return_amt_inc_tax AS return_amt,
         cr.cr_net_loss AS net_loss,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT wr.wr_returned_date_sk AS return_date_sk,
         wr.wr_web_page_sk AS entity_sk,
         wr.wr_return_amt_inc_tax AS return_amt,
         wr.wr_net_loss AS net_loss,
         'web' AS channel
  FROM web_returns wr
), sales_agg AS (
  SELECT
    su.channel,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    COALESCE(st.s_store_name, cc.cc_name, wp.wp_url) AS entity_name,
    SUM(su.net_paid) AS total_sales,
    SUM(su.net_profit) AS total_profit
  FROM sales_union su
  JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
  LEFT JOIN store st ON su.entity_sk = st.s_store_sk AND su.channel = 'store'
  LEFT JOIN call_center cc ON su.entity_sk = cc.cc_call_center_sk AND su.channel = 'catalog'
  LEFT JOIN web_page wp ON su.entity_sk = wp.wp_web_page_sk AND su.channel = 'web'
  WHERE d.d_year = 2001
  GROUP BY su.channel,
           d.d_year,
           d.d_month_seq,
           COALESCE(st.s_store_name, cc.cc_name, wp.wp_url)
), returns_agg AS (
  SELECT
    ru.channel,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    COALESCE(st.s_store_name, cc.cc_name, wp.wp_url) AS entity_name,
    SUM(ru.return_amt) AS total_returns,
    SUM(ru.net_loss) AS total_loss
  FROM returns_union ru
  JOIN date_dim d ON ru.return_date_sk = d.d_date_sk
  LEFT JOIN store st ON ru.entity_sk = st.s_store_sk AND ru.channel = 'store'
  LEFT JOIN call_center cc ON ru.entity_sk = cc.cc_call_center_sk AND ru.channel = 'catalog'
  LEFT JOIN web_page wp ON ru.entity_sk = wp.wp_web_page_sk AND ru.channel = 'web'
  WHERE d.d_year = 2001
  GROUP BY ru.channel,
           d.d_year,
           d.d_month_seq,
           COALESCE(st.s_store_name, cc.cc_name, wp.wp_url)
)
SELECT
  s.channel,
  s.year,
  s.month_seq,
  s.entity_name,
  s.total_sales,
  COALESCE(r.total_returns, 0) AS total_returns,
  s.total_profit - COALESCE(r.total_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.channel = r.channel
  AND s.year = r.year
  AND s.month_seq = r.month_seq
  AND s.entity_name = r.entity_name
ORDER BY s.channel, s.year, s.month_seq, net_profit_after_returns DESC
LIMIT 200
