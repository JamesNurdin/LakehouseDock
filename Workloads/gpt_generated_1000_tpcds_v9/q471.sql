WITH agg AS (
    SELECT
        cp.cp_department,
        s.s_store_name,
        dr.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE 
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High'
            WHEN SUM(cr.cr_net_loss) > 500 THEN 'Medium'
            ELSE 'Low'
        END AS loss_severity
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN store s
        ON s.s_closed_date_sk = dr.d_date_sk
    JOIN date_dim dp_start
        ON cp.cp_start_date_sk = dp_start.d_date_sk
    WHERE dr.d_year = 2001
      AND s.s_state = 'CA'
      AND cp.cp_type = 'Catalog'
      AND dp_start.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND cr.cr_return_quantity > 0
    GROUP BY GROUPING SETS (
        (cp.cp_department, s.s_store_name, dr.d_year),
        (cp.cp_department, dr.d_year),
        (s.s_store_name, dr.d_year),
        (dr.d_year)
    )
)
SELECT
    cp_department,
    s_store_name,
    d_year,
    total_net_loss,
    total_return_amount,
    loss_severity,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY d_year, loss_rank
LIMIT 100
