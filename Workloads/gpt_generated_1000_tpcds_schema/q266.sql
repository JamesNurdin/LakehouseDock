WITH combined AS (
    (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            d.d_year,
            r.r_reason_desc,
            cr.cr_returning_customer_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_year = 2001
          AND cr.cr_return_amount > 100
    )
    UNION
    (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            d.d_year,
            r.r_reason_desc,
            cr.cr_returning_customer_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_year = 2002
          AND cr.cr_return_amount > 100
    )
    INTERSECT
    (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            d.d_year,
            r.r_reason_desc,
            cr.cr_returning_customer_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_year IN (2001, 2002)
          AND cr.cr_return_amount > 150
    )
)
SELECT
    combined.cr_order_number,
    combined.cr_return_amount,
    combined.d_year,
    combined.r_reason_desc,
    (
        SELECT SUM(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_returning_customer_sk = combined.cr_returning_customer_sk
    ) AS total_return_by_customer
FROM combined
ORDER BY combined.cr_return_amount DESC
LIMIT 100
