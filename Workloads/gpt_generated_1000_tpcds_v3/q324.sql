WITH return_by_customer AS (
    SELECT
        c_refunded.c_salutation AS salutation,
        c_refunded.c_birth_month AS birth_month,
        CASE 
            WHEN cr.cr_return_amount > 200 THEN 'High'
            WHEN cr.cr_return_amount > 100 THEN 'Medium'
            ELSE 'Low'
        END AS return_amount_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    WHERE cr.cr_reversed_charge > 100
        AND cr.cr_return_quantity >= 1
        AND cr.cr_return_amount BETWEEN 10 AND 500
        AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2451500
        AND c_refunded.c_birth_month IN (1, 7, 9, 12)
        AND c_refunded.c_salutation = 'Mr.'
        AND c_returning.c_birth_year >= 1970
    GROUP BY
        c_refunded.c_salutation,
        c_refunded.c_birth_month,
        CASE 
            WHEN cr.cr_return_amount > 200 THEN 'High'
            WHEN cr.cr_return_amount > 100 THEN 'Medium'
            ELSE 'Low'
        END
)
SELECT
    salutation,
    birth_month,
    AVG(total_return_amount) AS avg_total_return_amount,
    SUM(return_cnt) AS total_returns,
    SUM(total_net_loss) AS sum_net_loss
FROM return_by_customer
GROUP BY salutation, birth_month
HAVING AVG(total_return_amount) > 300
ORDER BY avg_total_return_amount DESC
LIMIT 100
