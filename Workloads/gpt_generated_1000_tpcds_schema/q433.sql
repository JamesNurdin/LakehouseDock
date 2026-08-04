WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS transactions
    FROM store s
    FULL OUTER JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_store_id IN (
          SELECT cp.cp_catalog_page_id
          FROM catalog_page cp
          WHERE cp.cp_department = 'Electronics'
      )
      AND ss.ss_net_paid > (
          SELECT MAX(ss2.ss_net_paid)
          FROM store_sales ss2
          WHERE ss2.ss_sold_date_sk = (
              SELECT MIN(d2.d_date_sk)
              FROM date_dim d2
              WHERE d2.d_year = 1999
          )
      )
    GROUP BY s.s_store_id, d.d_year
),
catalog_returns_agg AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE w.w_state IN (
        SELECT DISTINCT s2.s_state
        FROM store s2
        WHERE s2.s_company_id = 1
    )
    GROUP BY w.w_warehouse_name, d.d_year
)
SELECT
    ssa.s_store_id AS entity,
    ssa.d_year AS year,
    ssa.total_net_paid AS metric_value,
    'Store Net Paid' AS metric_type
FROM store_sales_agg ssa
WHERE ssa.s_store_id IS NOT NULL
UNION ALL
SELECT
    cra.w_warehouse_name AS entity,
    cra.d_year AS year,
    cra.total_return_amount AS metric_value,
    'Warehouse Return Amount' AS metric_type
FROM catalog_returns_agg cra
WHERE cra.w_warehouse_name IS NOT NULL
ORDER BY year DESC, metric_value DESC
LIMIT 100
