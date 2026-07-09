WITH dept_monthly AS (
    SELECT
        cp.cp_department AS department,
        d.d_year AS year,
        d.d_moy AS month,
        cp.cp_type AS catalog_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND cp.cp_type IN ('quarterly', 'monthly')
    GROUP BY cp.cp_department, d.d_year, d.d_moy, cp.cp_type
)
SELECT
    department,
    year,
    month,
    catalog_type,
    total_net_loss,
    return_cnt,
    RANK() OVER (PARTITION BY year ORDER BY total_net_loss DESC) AS dept_year_rank,
    ROUND(total_net_loss / NULLIF(SUM(total_net_loss) OVER (PARTITION BY department), 0), 2) AS loss_ratio_to_dept_total
FROM dept_monthly
WHERE total_net_loss > 1000
ORDER BY total_net_loss DESC
LIMIT 15
