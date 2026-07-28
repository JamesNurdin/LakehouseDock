WITH
  overall_avg AS (
    SELECT AVG(cs_net_profit) AS avg_profit
    FROM catalog_sales
  ),

  bill_sales AS (
    SELECT
      promotion.p_promo_id,
      'Bill' AS link_type,
      SUM(catalog_sales.cs_net_profit) AS total_profit,
      CASE WHEN SUM(catalog_sales.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
      COUNT(DISTINCT catalog_sales.cs_order_number) AS distinct_orders,
      overall_avg.avg_profit
    FROM catalog_sales
    JOIN promotion
      ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN household_demographics
      ON catalog_sales.cs_bill_hdemo_sk = household_demographics.hd_demo_sk
    CROSS JOIN overall_avg
    WHERE promotion.p_channel_catalog = 'Y'
      AND catalog_sales.cs_ext_ship_cost > 0
      AND household_demographics.hd_vehicle_count >= 0
      AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = catalog_sales.cs_promo_sk
          AND p2.p_discount_active = 'Y'
      )
    GROUP BY promotion.p_promo_id, overall_avg.avg_profit
  ),

  ship_sales AS (
    SELECT
      promotion.p_promo_id,
      'Ship' AS link_type,
      SUM(catalog_sales.cs_net_profit) AS total_profit,
      CASE WHEN SUM(catalog_sales.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
      COUNT(DISTINCT catalog_sales.cs_order_number) AS distinct_orders,
      overall_avg.avg_profit
    FROM catalog_sales
    JOIN promotion
      ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN household_demographics
      ON catalog_sales.cs_ship_hdemo_sk = household_demographics.hd_demo_sk
    CROSS JOIN overall_avg
    WHERE promotion.p_channel_event = 'Y'
      AND catalog_sales.cs_ext_ship_cost = 0
      AND household_demographics.hd_dep_count IN (
        SELECT hd_dep_count
        FROM household_demographics
        WHERE hd_vehicle_count = 0
      )
    GROUP BY promotion.p_promo_id, overall_avg.avg_profit
  )

SELECT
  combined.p_promo_id,
  combined.link_type,
  combined.total_profit,
  combined.profit_category,
  combined.distinct_orders,
  combined.avg_profit
FROM (
  SELECT p_promo_id, link_type, total_profit, profit_category, distinct_orders, avg_profit FROM bill_sales
  UNION ALL
  SELECT p_promo_id, link_type, total_profit, profit_category, distinct_orders, avg_profit FROM ship_sales
) AS combined
ORDER BY combined.total_profit DESC
LIMIT 100
