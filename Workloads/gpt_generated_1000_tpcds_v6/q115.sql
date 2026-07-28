WITH sales_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_id,
        i.i_item_id,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS product_label,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(cp.cp_description, '(?i)promo')
      AND i.i_brand LIKE 'Brand%'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY cp.cp_department, cp.cp_catalog_page_id, i.i_item_id, i.i_brand, i.i_product_name
)
SELECT
    sa.cp_department,
    sa.cp_catalog_page_id,
    sa.i_item_id,
    sa.product_label,
    sa.total_profit,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS avg_year_profit,
    RANK() OVER (PARTITION BY sa.cp_department ORDER BY sa.total_profit DESC) AS dept_rank
FROM sales_agg sa
ORDER BY sa.total_profit DESC
LIMIT 100
