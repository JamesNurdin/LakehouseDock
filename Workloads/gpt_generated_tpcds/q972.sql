WITH all_sales AS (
  SELECT ss_promo_sk AS promo_sk,
         ss_sold_date_sk AS sold_date_sk,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit
  FROM store_sales
  UNION ALL
  SELECT cs_promo_sk AS promo_sk,
         cs_sold_date_sk AS sold_date_sk,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit
  FROM catalog_sales
  UNION ALL
  SELECT ws_promo_sk AS promo_sk,
         ws_sold_date_sk AS sold_date_sk,
         ws_net_paid AS net_paid,
         ws_net_profit AS net_profit
  FROM web_sales
)
SELECT
  promotion.p_promo_id,
  promotion.p_promo_name,
  date_dim.d_year,
  date_dim.d_month_seq,
  SUM(all_sales.net_paid) AS total_net_paid,
  SUM(all_sales.net_profit) AS total_net_profit,
  COUNT(*) AS total_transactions
FROM all_sales
JOIN promotion
  ON all_sales.promo_sk = promotion.p_promo_sk
JOIN date_dim
  ON all_sales.sold_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year = 2001
GROUP BY promotion.p_promo_id,
         promotion.p_promo_name,
         date_dim.d_year,
         date_dim.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 20
