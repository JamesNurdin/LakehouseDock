WITH cs_agg AS (
    SELECT i.i_item_id AS item_id,
           cp.cp_department AS department,
           SUM(cs.cs_net_profit) AS amount,
           'profit' AS metric_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2020
    GROUP BY i.i_item_id, cp.cp_department
),
cr_agg AS (
    SELECT i.i_item_id AS item_id,
           cp.cp_department AS department,
           SUM(cr.cr_net_loss) AS amount,
           'loss' AS metric_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2020
    GROUP BY i.i_item_id, cp.cp_department
),
combined AS (
    SELECT * FROM cs_agg
    UNION ALL
    SELECT * FROM cr_agg
)
SELECT
    item_id,
    department,
    metric_type,
    amount,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY amount DESC) AS dept_rank
FROM combined
ORDER BY department, dept_rank
LIMIT 100
