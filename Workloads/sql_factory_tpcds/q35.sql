SELECT
  i.i_item_id,
  i.i_brand,
  i.i_category,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cs.cs_quantity) AS total_quantity_sold,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  CASE
    WHEN SUM(cs.cs_net_profit) > 50000 THEN 'Very High'
    WHEN SUM(cs.cs_net_profit) > 20000 THEN 'High'
    WHEN SUM(cs.cs_net_profit) > 5000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_bracket,
  RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
  MAX(
    CASE
      WHEN p.p_channel_tv = 'Y' THEN 'TV'
      WHEN p.p_channel_email = 'Y' THEN 'Email'
      WHEN p.p_channel_radio = 'Y' THEN 'Radio'
      ELSE 'Other'
    END
  ) AS primary_promo_channel
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
GROUP BY i.i_item_id, i.i_brand, i.i_category
HAVING SUM(cs.cs_quantity) > 0
ORDER BY total_net_profit DESC
LIMIT 100
