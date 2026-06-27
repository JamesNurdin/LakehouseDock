WITH store_sales_monthly AS (
  SELECT
    p.p_promo_id,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    AND p.p_discount_active = 'Y'
  GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
catalog_sales_monthly AS (
  SELECT
    p.p_promo_id,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    AND p.p_discount_active = 'Y'
  GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
web_sales_monthly AS (
  SELECT
    p.p_promo_id,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    AND p.p_discount_active = 'Y'
  GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
combined_sales AS (
  SELECT p_promo_id, d_year, d_month_seq, total_net_paid, total_net_profit
  FROM store_sales_monthly
  UNION ALL
  SELECT p_promo_id, d_year, d_month_seq, total_net_paid, total_net_profit
  FROM catalog_sales_monthly
  UNION ALL
  SELECT p_promo_id, d_year, d_month_seq, total_net_paid, total_net_profit
  FROM web_sales_monthly
)
SELECT p_promo_id,
       d_year,
       d_month_seq,
       SUM(total_net_paid) AS sum_net_paid,
       SUM(total_net_profit) AS sum_net_profit
FROM combined_sales
GROUP BY p_promo_id, d_year, d_month_seq
ORDER BY sum_net_profit DESC
LIMIT 10
