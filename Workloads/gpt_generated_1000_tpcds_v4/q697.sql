WITH sales_returns AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    d.d_year,
    ws.ws_net_paid,
    ws.ws_net_profit,
    p.p_promo_name,
    r.r_reason_desc,
    ws.ws_bill_customer_sk,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn_latest,
    CASE
      WHEN regexp_like(p.p_promo_name, '(?i)clearance') THEN 'Clearance'
      ELSE 'Other'
    END AS promo_type
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE p.p_promo_name LIKE '%Discount%'
    AND regexp_like(p.p_promo_name, '(?i)discount')
)
SELECT
  d_year,
  p_promo_name,
  promo_type,
  COUNT(DISTINCT ws_order_number) AS orders,
  SUM(ws_net_paid) AS total_paid,
  SUM(ws_net_profit) AS total_profit,
  CASE WHEN SUM(ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  MAX(rn_latest) AS max_rank,
  regexp_extract(p_promo_name, '(?i)(Discount|Sale)', 1) AS promo_keyword,
  substring(r_reason_desc, 1, 10) AS reason_prefix
FROM sales_returns
GROUP BY d_year, p_promo_name, promo_type, r_reason_desc
HAVING COUNT(*) > 5
ORDER BY total_profit DESC
LIMIT 100
