WITH
  catalog_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           cc.cc_state AS state,
           i.i_category AS category,
           cs.cs_order_number AS order_id,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
  ),
  store_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           s.s_state AS state,
           i.i_category AS category,
           ss.ss_ticket_number AS order_id,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_discount_amt AS discount_amt,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
  ),
  web_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           w.web_state AS state,
           i.i_category AS category,
           ws.ws_order_number AS order_id,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_discount_amt AS discount_amt,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
  ),
  all_sales AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
  ),
  aggregated AS (
    SELECT
      state,
      channel,
      year,
      month,
      category,
      COUNT(DISTINCT order_id) AS orders,
      SUM(net_paid) AS total_net_paid,
      SUM(net_profit) AS total_net_profit,
      SUM(discount_amt) AS total_discount,
      ROUND(100.0 * SUM(discount_amt) / NULLIF(SUM(net_paid),0), 2) AS discount_pct
    FROM all_sales
    GROUP BY GROUPING SETS (
      (state, channel, year, month, category),
      (state, channel, year, month),
      (state, channel, year),
      (state, channel),
      (state),
      (year, month, channel),
      (year, month),
      (year)
    )
  )
SELECT
  state,
  channel,
  year,
  month,
  category,
  orders,
  total_net_paid,
  total_net_profit,
  total_discount,
  discount_pct,
  ROW_NUMBER() OVER (PARTITION BY state, year ORDER BY total_net_profit DESC) AS profit_state_rank,
  SUM(total_net_profit) OVER (PARTITION BY year) AS year_total_profit,
  ROUND(100.0 * total_net_profit / NULLIF(SUM(total_net_profit) OVER (PARTITION BY year),0), 2) AS profit_pct_of_year
FROM aggregated
WHERE total_net_paid IS NOT NULL
ORDER BY state, channel, year, month, category
