WITH avg_profit AS (
    SELECT avg(cs_net_profit) AS val
    FROM catalog_sales
),
union_data AS (
    SELECT
        cp.cp_catalog_page_id,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_tier,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS total_sales,
        (SELECT val FROM avg_profit) AS avg_all_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion pr ON cs.cs_promo_sk = pr.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 12
      AND pr.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_cost > 500
      )
    GROUP BY cp.cp_catalog_page_id

    UNION ALL

    SELECT
        cp.cp_catalog_page_id,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_tier,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS total_sales,
        (SELECT val FROM avg_profit) AS avg_all_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion pr ON cs.cs_promo_sk = pr.p_promo_sk
    WHERE td.t_hour BETWEEN 17 AND 20
      AND pr.p_discount_active = 'N'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_cost > 1000
      )
    GROUP BY cp.cp_catalog_page_id
)
SELECT *
FROM union_data
ORDER BY total_profit DESC
LIMIT 100
