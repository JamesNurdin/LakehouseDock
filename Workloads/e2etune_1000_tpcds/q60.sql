WITH catalog_agg AS (
  SELECT
    cs_promo_sk,
    SUM(cs_net_profit) AS catalog_net_profit,
    SUM(cs_ext_discount_amt) AS catalog_discount,
    COUNT(*) AS catalog_sales_cnt
  FROM catalog_sales
  WHERE cs_wholesale_cost > 50
  GROUP BY cs_promo_sk
),
web_agg AS (
  SELECT
    ws_promo_sk,
    SUM(ws_net_profit) AS web_net_profit,
    SUM(ws_ext_discount_amt) AS web_discount,
    COUNT(*) AS web_sales_cnt
  FROM web_sales
  WHERE ws_wholesale_cost > 50
  GROUP BY ws_promo_sk
),
promo_combined AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    p.p_channel_tv,
    COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(w.web_net_profit, 0) AS web_net_profit,
    COALESCE(c.catalog_discount, 0) AS catalog_discount,
    COALESCE(w.web_discount, 0) AS web_discount,
    COALESCE(c.catalog_sales_cnt, 0) AS catalog_sales_cnt,
    COALESCE(w.web_sales_cnt, 0) AS web_sales_cnt
  FROM promotion p
  LEFT JOIN catalog_agg c ON p.p_promo_sk = c.cs_promo_sk
  LEFT JOIN web_agg w ON p.p_promo_sk = w.ws_promo_sk
  WHERE p.p_start_date_sk >= 2450000
)
SELECT
  p_promo_name,
  p_channel_tv,
  (catalog_net_profit + web_net_profit) AS total_net_profit,
  (catalog_discount + web_discount) AS total_discount,
  CASE WHEN (catalog_sales_cnt + web_sales_cnt) > 0 THEN
    (catalog_discount + web_discount) / (catalog_sales_cnt + web_sales_cnt)
  ELSE 0 END AS avg_discount_per_sale,
  RANK() OVER (ORDER BY (catalog_net_profit + web_net_profit) DESC) AS profit_rank
FROM promo_combined
WHERE (catalog_net_profit + web_net_profit) > 1000
ORDER BY profit_rank
LIMIT 20
