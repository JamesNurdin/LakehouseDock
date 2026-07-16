WITH store_sales_enriched AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_net_profit AS net_profit,
    'store' AS channel,
    s.s_state AS state,
    i.i_category AS category,
    p.p_promo_id AS promo_id
  FROM store_sales ss
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
catalog_sales_enriched AS (
  SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_net_profit AS net_profit,
    'catalog' AS channel,
    cc.cc_state AS state,
    i.i_category AS category,
    p.p_promo_id AS promo_id
  FROM catalog_sales cs
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
web_sales_enriched AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_net_profit AS net_profit,
    'web' AS channel,
    w.w_state AS state,
    i.i_category AS category,
    p.p_promo_id AS promo_id
  FROM web_sales ws
  LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
unified_sales AS (
  SELECT * FROM store_sales_enriched
  UNION ALL
  SELECT * FROM catalog_sales_enriched
  UNION ALL
  SELECT * FROM web_sales_enriched
),
filtered_sales AS (
  SELECT
    us.customer_sk,
    us.channel,
    d.d_year,
    d.d_month_seq,
    us.state,
    us.category,
    us.promo_id,
    us.net_profit
  FROM unified_sales us
  JOIN date_dim d ON us.date_sk = d.d_date_sk
  WHERE d.d_year = 2001
),
agg_sales AS (
  SELECT
    c.c_customer_id,
    f.d_year,
    f.d_month_seq,
    f.channel,
    f.state,
    f.category,
    f.promo_id,
    SUM(f.net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt
  FROM filtered_sales f
  JOIN customer c ON f.customer_sk = c.c_customer_sk
  GROUP BY
    c.c_customer_id,
    f.d_year,
    f.d_month_seq,
    f.channel,
    f.state,
    f.category,
    f.promo_id
  HAVING SUM(f.net_profit) > 0
)
SELECT
  a.c_customer_id,
  a.d_year,
  a.d_month_seq,
  a.channel,
  a.state,
  a.category,
  a.promo_id,
  a.total_net_profit,
  a.transaction_cnt,
  ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS rank_by_year,
  SUM(a.total_net_profit) OVER (
    PARTITION BY a.d_year
    ORDER BY a.total_net_profit DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_profit
FROM agg_sales a
ORDER BY a.d_year, a.total_net_profit DESC
LIMIT 100
