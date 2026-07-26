WITH ship_sales AS (
  SELECT
    cs.cs_ship_addr_sk AS addr_sk,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ws.ws_ship_addr_sk,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_promo_sk
  FROM web_sales ws
)
SELECT
  ca.ca_county,
  ca.ca_state,
  COUNT(*) AS total_shipments,
  AVG(s.net_profit) AS avg_net_profit,
  AVG(s.discount_amt) AS avg_discount,
  SUM(s.net_profit) AS total_profit,
  p.p_promo_name,
  CASE
    WHEN p.p_discount_active = 'Y' THEN 'Active'
    ELSE 'Inactive'
  END AS promo_status,
  RANK() OVER (ORDER BY AVG(s.net_profit) DESC) AS profit_rank,
  DENSE_RANK() OVER (ORDER BY SUM(s.net_profit) DESC) AS profit_dense_rank
FROM ship_sales s
JOIN customer_address ca ON s.addr_sk = ca.ca_address_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
GROUP BY ca.ca_county, ca.ca_state, p.p_promo_name, p.p_discount_active
ORDER BY profit_rank
LIMIT 20
