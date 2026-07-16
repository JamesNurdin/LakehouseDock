SELECT
  i.i_class,
  cs.cs_sold_date_sk AS sold_date_sk,
  SUM(cs.cs_net_profit) AS daily_net_profit,
  AVG(SUM(cs.cs_net_profit)) OVER (
    PARTITION BY i.i_class
    ORDER BY cs.cs_sold_date_sk
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS three_day_moving_avg_profit,
  CASE
    WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High'
    WHEN SUM(cs.cs_net_profit) > 0 THEN 'Positive'
    ELSE 'Negative'
  END AS profit_category,
  MAX(p.p_discount_active) AS discount_active_flag
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
GROUP BY i.i_class, cs.cs_sold_date_sk
ORDER BY i.i_class, cs.cs_sold_date_sk
LIMIT 200
