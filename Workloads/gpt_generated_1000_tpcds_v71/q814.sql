WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)steel')
),
aggregated AS (
    SELECT
        c.c_customer_id,
        c.c_email_address,
        ca.ca_state,
        d.d_year,
        r.r_reason_desc,
        SUM(b.cr_return_amount) AS total_return_amount,
        SUM(b.cr_net_loss) AS total_net_loss
    FROM base b
    JOIN customer c
        ON b.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON b.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON b.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d
        ON b.cr_returned_date_sk = d.d_date_sk
    WHERE c.c_email_address LIKE '%@example.com'
    GROUP BY
        c.c_customer_id,
        c.c_email_address,
        ca.ca_state,
        d.d_year,
        r.r_reason_desc
)
SELECT
    c_customer_id,
    c_email_address,
    ca_state,
    d_year,
    total_return_amount,
    total_net_loss,
    regexp_extract(r_reason_desc, '^([^ ]+)', 1) AS reason_first_word,
    rank() OVER (PARTITION BY ca_state ORDER BY total_return_amount DESC) AS state_rank
FROM aggregated
ORDER BY total_return_amount DESC, state_rank
LIMIT 100
