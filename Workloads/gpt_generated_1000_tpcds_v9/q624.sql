SELECT
    c.c_customer_id,
    td.t_hour,
    CASE
        WHEN SUM(CASE WHEN sr.sr_return_amt_inc_tax > 1000 THEN sr.sr_return_amt_inc_tax ELSE 0 END) >
             SUM(CASE WHEN sr.sr_return_amt_inc_tax <= 1000 THEN sr.sr_return_amt_inc_tax ELSE 0 END)
            THEN 'More High'
        ELSE 'More Low'
    END AS high_vs_low_category,
    COUNT(*) AS total_returns,
    SUM(sr.sr_return_amt_inc_tax) AS sum_return_inc_tax,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_inc_tax,
    MIN(sr.sr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(sr.sr_return_amt_inc_tax) AS max_return_inc_tax,
    SUM(cr.cr_return_amount) AS sum_catalog_return_amount,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount
FROM
    store_returns sr
JOIN
    time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
JOIN
    customer c
        ON sr.sr_customer_sk = c.c_customer_sk
JOIN
    catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
WHERE
    c.c_birth_month = 5
    AND c.c_birth_day IN (11, 23)
    AND td.t_hour BETWEEN 9 AND 17
    AND sr.sr_return_amt_inc_tax > 1000
    AND cr.cr_return_amount > 500
    AND cr.cr_reversed_charge < 200
    AND EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
          AND cp.cp_department = 'Electronics'
          AND cp.cp_type = 'Standard'
    )
GROUP BY GROUPING SETS (
    (c.c_customer_id, td.t_hour),
    (c.c_customer_id),
    (td.t_hour),
    ()
)
ORDER BY
    c.c_customer_id ASC,
    td.t_hour ASC
