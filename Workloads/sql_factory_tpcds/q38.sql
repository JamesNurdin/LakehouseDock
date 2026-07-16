SELECT
  p.p_promo_sk,
  p.p_promo_name,
  COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
  AVG(cs.cs_ext_discount_amt) AS avg_discount_per_sale,
  CASE
    WHEN SUM(cs.cs_ext_discount_amt) = 0 THEN NULL
    ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_ext_discount_amt)
  END AS profit_to_discount_ratio,
  CASE
    WHEN p.p_cost > SUM(cs.cs_net_profit) THEN 'Costly'
    ELSE 'Profitable'
  END AS promotion_cost_status,
  DENSE_RANK() OVER (
    ORDER BY
      CASE
        WHEN SUM(cs.cs_ext_discount_amt) = 0 THEN 0
        ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_ext_discount_amt)
      END DESC
  ) AS profitability_rank,
  AVG(i.i_current_price) AS avg_item_current_price
FROM promotion p
JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
GROUP BY p.p_promo_sk, p.p_promo_name, p.p_cost
HAVING SUM(cs.cs_net_profit) > 0
ORDER BY profit_to_discount_ratio DESC
LIMIT 30
