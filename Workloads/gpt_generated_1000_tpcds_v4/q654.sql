WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cust.c_email_address,
        cust.c_first_name,
        cust.c_last_name,
        sm.sm_code,
        sm.sm_type
    FROM catalog_returns cr
    JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(cust.c_email_address, '\\.com$')
      AND substring(cust.c_first_name, 1, 1) = 'A'
      AND concat(cust.c_first_name, ' ', cust.c_last_name) LIKE '%Smith%'
      AND regexp_like(sm.sm_code, '^SM[0-9]{2}$')
)
SELECT
    d.d_year,
    d.d_month_seq,
    fr.sm_type,
    sum(fr.cr_return_amount) AS total_return_amount,
    sum(fr.cr_net_loss) AS total_net_loss,
    count(*) AS return_count,
    regexp_extract(fr.sm_code, '[0-9]+') AS ship_mode_number
FROM filtered_returns fr
JOIN date_dim d
    ON fr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    d.d_year,
    d.d_month_seq,
    fr.sm_type,
    regexp_extract(fr.sm_code, '[0-9]+')
ORDER BY
    d.d_year,
    d.d_month_seq,
    fr.sm_type
