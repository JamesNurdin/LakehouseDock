WITH promo_monthly AS (
    SELECT
        p.p_promo_name,
        w.w_warehouse_name,
        d.d_year,
        month(d.d_date) AS month,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) / NULLIF(COUNT(*), 0) AS avg_profit_per_sale
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount')
      AND cp.cp_description LIKE '%hand%'
      AND d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
          WHERE ss.ss_promo_sk = p.p_promo_sk
            AND d2.d_year = d.d_year
      )
    GROUP BY p.p_promo_name, w.w_warehouse_name, d.d_year, month(d.d_date)
)
SELECT
    pm.p_promo_name,
    substring(pm.p_promo_name, 1, 10) AS promo_name_prefix,
    pm.w_warehouse_name,
    concat(pm.p_promo_name, ' - ', pm.w_warehouse_name) AS promo_warehouse,
    pm.d_year,
    pm.month,
    pm.distinct_items_sold,
    pm.total_net_profit,
    pm.total_sales,
    CASE WHEN pm.total_net_profit > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
    pm.avg_profit_per_sale,
    overall.overall_avg_net_profit,
    pm.total_net_profit / NULLIF(overall.overall_avg_net_profit, 0) AS profit_vs_overall_ratio
FROM promo_monthly pm
CROSS JOIN (
    SELECT AVG(cs2.cs_net_profit) AS overall_avg_net_profit
    FROM catalog_sales cs2
) overall
ORDER BY pm.total_net_profit DESC
LIMIT 100
