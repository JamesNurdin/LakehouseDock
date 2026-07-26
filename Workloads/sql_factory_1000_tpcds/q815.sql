WITH profit_by_ship AS (
  SELECT
      p.p_promo_name,
      sm.sm_ship_mode_id,
      cd.cd_gender,
      SUM(cs.cs_net_profit) AS total_net_profit,
      CASE
          WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High'
          WHEN SUM(cs.cs_net_profit) > 50000 THEN 'Medium'
          ELSE 'Low'
      END AS profit_category,
      RANK() OVER (PARTITION BY p.p_promo_name ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  GROUP BY p.p_promo_name, sm.sm_ship_mode_id, cd.cd_gender
)
SELECT
    p_promo_name,
    sm_ship_mode_id,
    cd_gender,
    total_net_profit,
    profit_category,
    profit_rank
FROM profit_by_ship
WHERE profit_rank <= 5
ORDER BY p_promo_name, profit_rank, cd_gender
