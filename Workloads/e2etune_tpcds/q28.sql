WITH sales_agg AS (
  SELECT
    ws.ws_web_site_sk,
    i.i_category,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(CASE WHEN ws.ws_ext_sales_price > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_sales_price END) AS avg_discount_ratio
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_demographics bd ON ws.ws_bill_cdemo_sk = bd.cd_demo_sk
  WHERE bd.cd_credit_rating = 'Good'
    AND bd.cd_purchase_estimate >= 1500
    AND p.p_discount_active = 'Y'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
  GROUP BY ws.ws_web_site_sk, i.i_category
)
SELECT
  ws.web_name,
  agg.i_category,
  agg.total_net_profit,
  agg.total_quantity,
  agg.avg_discount_ratio,
  RANK() OVER (PARTITION BY ws.web_name ORDER BY agg.total_net_profit DESC) AS category_profit_rank
FROM sales_agg agg
JOIN web_site ws ON agg.ws_web_site_sk = ws.web_site_sk
ORDER BY ws.web_name, category_profit_rank
LIMIT 100
