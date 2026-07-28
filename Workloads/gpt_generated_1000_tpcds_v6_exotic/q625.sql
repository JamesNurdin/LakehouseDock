WITH avg_promo_cost AS (
    SELECT avg(p_cost) AS avg_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
),
store_summary AS (
    SELECT
        CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS sales_type,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        'store' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Books'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END
),
catalog_summary AS (
    SELECT
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS sales_type,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Books'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END
)
SELECT
    s.sales_type,
    s.total_sales,
    s.total_profit,
    s.source,
    (s.total_profit / NULLIF(s.total_sales, 0)) AS profit_margin,
    pc.avg_cost
FROM (
    SELECT * FROM store_summary
    UNION ALL
    SELECT * FROM catalog_summary
) s
CROSS JOIN avg_promo_cost pc
ORDER BY profit_margin DESC, s.source
LIMIT 100
