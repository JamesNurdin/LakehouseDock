SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_tax_percentage,
    d.d_year,
    r.r_reason_desc,
    CASE
        WHEN (d.d_year - c_refund.c_birth_year) < 30 THEN 'Under 30'
        WHEN (d.d_year - c_refund.c_birth_year) BETWEEN 30 AND 39 THEN '30s'
        WHEN (d.d_year - c_refund.c_birth_year) BETWEEN 40 AND 49 THEN '40s'
        ELSE '50+'
    END AS refund_customer_age_group,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_tax) AS total_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount + cr.cr_fee + cr.cr_return_tax) AS total_loss_including_fees,
    AVG(d.d_year - c_refund.c_birth_year) AS avg_refund_customer_age,
    AVG(d.d_year - c_return.c_birth_year) AS avg_returning_customer_age,
    (AVG(d.d_year - c_refund.c_birth_year) - AVG(d.d_year - c_return.c_birth_year)) AS age_difference
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer c_return
    ON cr.cr_returning_customer_sk = c_return.c_customer_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_tax_percentage,
    d.d_year,
    r.r_reason_desc,
    CASE
        WHEN (d.d_year - c_refund.c_birth_year) < 30 THEN 'Under 30'
        WHEN (d.d_year - c_refund.c_birth_year) BETWEEN 30 AND 39 THEN '30s'
        WHEN (d.d_year - c_refund.c_birth_year) BETWEEN 40 AND 49 THEN '40s'
        ELSE '50+'
    END
