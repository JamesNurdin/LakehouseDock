WITH unified_sales AS (
  SELECT cs.cs_sold_date_sk AS sale_date_sk,
         cs.cs_sold_time_sk AS sale_time_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_order_number AS order_number,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         cs.cs_call_center_sk AS channel_key,
         'catalog' AS channel,
         cs.cs_quantity AS quantity
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_sold_time_sk,
         ss.ss_item_sk,
         ss.ss_customer_sk,
         ss.ss_ticket_number,
         ss.ss_net_paid,
         ss.ss_net_profit,
         ss.ss_store_sk,
         'store',
         ss.ss_quantity
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_sold_time_sk,
         ws.ws_item_sk,
         ws.ws_bill_customer_sk,
         ws.ws_order_number,
         ws.ws_net_paid,
         ws.ws_net_profit,
         ws.ws_web_page_sk,
         'web',
         ws.ws_quantity
  FROM web_sales ws
), sales_with_dim AS (
  SELECT
    us.*,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(cc.cc_name, s.s_store_name, wp.wp_url, 'UNKNOWN') AS channel_name,
    (SELECT MAX(sr.sr_return_amt) FROM store_returns sr WHERE sr.sr_item_sk = us.item_sk AND sr.sr_returned_date_sk = us.sale_date_sk) AS max_store_return_amt,
    (SELECT MAX(cr.cr_return_amount) FROM catalog_returns cr WHERE cr.cr_item_sk = us.item_sk AND cr.cr_returned_date_sk = us.sale_date_sk) AS max_catalog_return_amt,
    (SELECT MAX(wr.wr_return_amt) FROM web_returns wr WHERE wr.wr_item_sk = us.item_sk AND wr.wr_returned_date_sk = us.sale_date_sk) AS max_web_return_amt,
    CASE
      WHEN us.net_paid = 0 THEN NULL
      ELSE us.net_profit / us.net_paid
    END AS profit_ratio,
    CONCAT(us.channel, '|', CAST(d.d_year AS VARCHAR), '|', CAST(d.d_month_seq AS VARCHAR)) AS grp_key,
    CASE WHEN MOD(us.order_number, 2) = 0 THEN NULLIF(us.net_paid, us.net_paid) ELSE us.net_paid END AS even_order_net_paid,
    LAG(us.net_paid) OVER (PARTITION BY us.channel ORDER BY us.sale_date_sk, us.sale_time_sk) AS prev_net_paid,
    SUM(us.net_paid) OVER (PARTITION BY us.channel ORDER BY us.sale_date_sk, us.sale_time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid
  FROM unified_sales us
  LEFT JOIN date_dim d
    ON us.sale_date_sk = d.d_date_sk
  LEFT JOIN call_center cc
    ON us.channel = 'catalog' AND us.channel_key = cc.cc_call_center_sk
  LEFT JOIN store s
    ON us.channel = 'store' AND us.channel_key = s.s_store_sk
  LEFT JOIN web_page wp
    ON us.channel = 'web' AND us.channel_key = wp.wp_web_page_sk
), rank_sales AS (
  SELECT
    swd.*,
    ROW_NUMBER() OVER (PARTITION BY swd.channel ORDER BY swd.net_paid DESC) AS channel_rank,
    PERCENT_RANK() OVER (PARTITION BY swd.channel ORDER BY swd.net_paid) AS net_paid_percent_rank,
    COUNT(*) OVER (PARTITION BY swd.channel) AS total_sales_per_channel
  FROM sales_with_dim swd
), final_stats AS (
  SELECT
    rs.channel,
    rs.channel_name,
    rs.channel_rank,
    rs.net_paid,
    rs.profit_ratio,
    rs.max_store_return_amt,
    rs.max_catalog_return_amt,
    rs.max_web_return_amt,
    rs.cum_net_paid,
    rs.prev_net_paid,
    rs.total_sales_per_channel,
    CASE WHEN rs.channel_rank <= 5 THEN 'TOP5' ELSE 'OTHERS' END AS rank_category,
    (rs.net_paid - COALESCE(rs.prev_net_paid, 0)) / NULLIF(rs.net_paid, 0) AS delta_vs_prev_ratio,
    CASE
      WHEN rs.channel_name LIKE '%Inc%' THEN 'INC'
      WHEN rs.channel_name LIKE '%LLC%' THEN 'LLC'
      ELSE 'OTHER'
    END AS org_type
  FROM rank_sales rs
  WHERE rs.net_paid IS NOT NULL
)
SELECT
  channel,
  channel_name,
  channel_rank,
  net_paid,
  profit_ratio,
  max_store_return_amt,
  max_catalog_return_amt,
  max_web_return_amt,
  cum_net_paid,
  prev_net_paid,
  total_sales_per_channel,
  rank_category,
  delta_vs_prev_ratio,
  org_type
FROM (
  SELECT *
  FROM final_stats
  WHERE (rank_category = 'TOP5' AND profit_ratio > 0.2)
     OR (rank_category = 'OTHERS' AND delta_vs_prev_ratio < -0.5)
  UNION ALL
  SELECT
    channel,
    channel_name,
    CAST(NULL AS INTEGER) AS channel_rank,
    SUM(net_paid) AS net_paid,
    CAST(NULL AS DOUBLE) AS profit_ratio,
    MAX(max_store_return_amt) AS max_store_return_amt,
    MAX(max_catalog_return_amt) AS max_catalog_return_amt,
    MAX(max_web_return_amt) AS max_web_return_amt,
    SUM(cum_net_paid) AS cum_net_paid,
    CAST(NULL AS DECIMAL(7,2)) AS prev_net_paid,
    SUM(total_sales_per_channel) AS total_sales_per_channel,
    'AGG' AS rank_category,
    CAST(NULL AS DOUBLE) AS delta_vs_prev_ratio,
    CAST(NULL AS VARCHAR) AS org_type
  FROM final_stats
  GROUP BY channel, channel_name
) AS combined
ORDER BY channel, channel_rank
LIMIT 100
