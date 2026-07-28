WITH sales_data AS (
    SELECT
        cp.cp_department AS department,
        i.i_brand AS brand,
        CASE 
            WHEN cs.cs_net_paid_inc_ship_tax > 5000 THEN 'High'
            WHEN cs.cs_net_paid_inc_ship_tax > 2000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_level,
        cs.cs_net_paid_inc_ship_tax,
        ss.ss_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    WHERE cs.cs_warehouse_sk IN (13, 14)
      AND cp.cp_department = 'Sports'
      AND i.i_container = 'Unknown'
      AND cs.cs_promo_sk = 1472
      AND EXISTS (
          SELECT 1 FROM store s
          WHERE s.s_store_sk = ss.ss_store_sk
            AND s.s_hours = '8AM-4PM'
            AND s.s_state = 'CA'
      )
),
agg AS (
    SELECT
        department,
        brand,
        revenue_level,
        COUNT(*) AS transaction_cnt,
        SUM(cs_net_paid_inc_ship_tax) AS total_revenue,
        AVG(ss_net_profit) AS avg_profit,
        MIN(cs_net_paid_inc_ship_tax) AS min_revenue,
        MAX(cs_net_paid_inc_ship_tax) AS max_revenue
    FROM sales_data
    GROUP BY department, brand, revenue_level
)
SELECT
    department,
    brand,
    revenue_level,
    transaction_cnt,
    total_revenue,
    avg_profit,
    min_revenue,
    max_revenue,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY total_revenue DESC) AS dept_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 100
