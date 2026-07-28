WITH filtered_returns AS (
    SELECT
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        regexp_extract(c.c_email_address, '@(.+)$') AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        r.r_reason_desc,
        sm.sm_carrier
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND c.c_first_name LIKE 'A%'
      AND regexp_like(r.r_reason_desc, '(?i)damaged')
      AND sm.sm_carrier LIKE 'UPS%'
)
SELECT
    d.d_year,
    d.d_month_seq,
    fr.email_domain,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM filtered_returns fr
JOIN date_dim d
    ON fr.cr_returned_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_month_seq,
    fr.email_domain
ORDER BY
    d.d_year,
    d.d_month_seq,
    total_net_loss DESC
