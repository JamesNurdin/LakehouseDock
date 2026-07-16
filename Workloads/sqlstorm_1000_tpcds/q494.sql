WITH all_sales AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_store_sk AS store_sk,
    ss.ss_promo_sk AS promo_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit
  FROM store_sales ss
  UNION ALL
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_bill_customer_sk,
    NULL,
    cs.cs_promo_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    NULL,
    ws.ws_promo_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit
  FROM web_sales ws
)
SELECT
  d.d_year,
  d.d_month_seq,
  p.p_promo_name,
  sum(s.quantity) AS total_quantity,
  sum(s.net_paid) AS total_net_paid,
  sum(s.net_profit) AS total_net_profit,
  count(DISTINCT s.customer_sk) AS distinct_customers
FROM all_sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY d.d_year, d.d_month_seq, p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
