WITH base_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d.d_year,
        d.d_moy,
        s.s_division_id,
        s.s_number_employees
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_moy IN (4, 10)
      AND d.d_year = 2001
      AND cr.cr_return_quantity > 20
      AND s.s_number_employees BETWEEN 250 AND 300
),
union_data AS (
    SELECT
        d_year,
        d_moy,
        s_division_id,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM base_data
    WHERE s_division_id = 1
    GROUP BY d_year, d_moy, s_division_id

    UNION ALL

    SELECT
        d_year,
        d_moy,
        s_division_id,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM base_data
    WHERE s_division_id <> 1
    GROUP BY d_year, d_moy, s_division_id
)
SELECT
    d_year,
    AVG(total_net_loss) AS avg_loss_per_division,
    SUM(returns_cnt) AS total_returns
FROM union_data
GROUP BY d_year
HAVING SUM(returns_cnt) > 100
ORDER BY avg_loss_per_division DESC
LIMIT 100
