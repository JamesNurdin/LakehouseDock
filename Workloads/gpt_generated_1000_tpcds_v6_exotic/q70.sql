WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_fee,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss
    FROM
        catalog_returns cr
    WHERE
        cr.cr_fee > 30
        AND cr.cr_return_amt_inc_tax >= 500
        AND cr.cr_net_loss IS NOT NULL
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_email_address,
        c.c_current_addr_sk
    FROM
        customer c
    WHERE
        c.c_birth_year BETWEEN 1960 AND 1980
        AND c.c_preferred_cust_flag = 'Y'
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer_address ca
    WHERE
        ca.ca_country = 'United States'
)
SELECT DISTINCT
    crf.cr_order_number,
    crf.cr_returned_date_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.c_birth_year,
    ai.ca_city,
    ai.ca_state,
    crf.cr_fee,
    crf.cr_return_amt_inc_tax,
    crf.cr_net_loss,
    RANK() OVER (PARTITION BY ci.c_customer_sk ORDER BY crf.cr_net_loss DESC) AS loss_rank,
    ROW_NUMBER() OVER (ORDER BY crf.cr_return_amt_inc_tax DESC) AS global_amount_rownum
FROM
    filtered_returns crf
JOIN
    customer_info ci
        ON crf.cr_refunded_customer_sk = ci.c_customer_sk
JOIN
    address_info ai
        ON ci.c_current_addr_sk = ai.ca_address_sk
WHERE
    NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = crf.cr_refunded_customer_sk
          AND cr2.cr_fee = 0
    )
ORDER BY
    loss_rank ASC,
    crf.cr_return_amt_inc_tax DESC
LIMIT 100
