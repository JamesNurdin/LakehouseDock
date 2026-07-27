WITH agg AS (
    SELECT
        w.w_warehouse_name        AS w_warehouse_name,
        w.w_city                 AS w_city,
        d.d_year                 AS d_year,
        d.d_quarter_seq          AS d_quarter_seq,
        wp.wp_type               AS wp_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee)           AS avg_fee,
        SUM(cr.cr_return_quantity) AS total_quantity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                   -- filter 1
      AND d.d_quarter_seq = 14                               -- filter 2
      AND cr.cr_return_quantity > 5                          -- filter 3
      AND cr.cr_fee BETWEEN 10 AND 50                        -- filter 4
      AND w.w_city IN ('Los Angeles', 'New York', 'Chicago')-- filter 5
      AND wp.wp_type = 'product'                             -- filter 6
    GROUP BY
        w.w_warehouse_name,
        w.w_city,
        d.d_year,
        d.d_quarter_seq,
        wp.wp_type
)
SELECT
    w_warehouse_name,
    w_city,
    d_year,
    d_quarter_seq,
    wp_type,
    total_return_amount,
    avg_fee,
    total_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS revenue_rank,
    SUM(total_return_amount) OVER (
        PARTITION BY w_city
        ORDER BY total_return_amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_city
FROM agg
ORDER BY d_year DESC, revenue_rank
LIMIT 100
