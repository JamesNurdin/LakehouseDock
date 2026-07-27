WITH manager_sales AS (
    SELECT
        i.i_manager_id,
        i.i_size,
        regexp_extract(i.i_formulation, '([a-z]+)', 1) AS formulation_alpha,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND regexp_like(i.i_item_desc, '\\d')
      AND (i.i_size LIKE 'large%' OR i.i_size LIKE 'small%')
    GROUP BY i.i_manager_id, i.i_size, regexp_extract(i.i_formulation, '([a-z]+)', 1)
)
SELECT
    ms.i_manager_id,
    ms.i_size,
    ms.formulation_alpha,
    ms.total_net_paid,
    ms.sales_cnt,
    CONCAT('Mgr', CAST(ms.i_manager_id AS VARCHAR), '-', ms.i_size) AS manager_size_label
FROM manager_sales ms
WHERE ms.total_net_paid > (
    SELECT AVG(total_net_paid) * 1.2
    FROM manager_sales
)
ORDER BY ms.total_net_paid DESC
LIMIT 100
