WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_current_hdemo_sk,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        CASE
            WHEN regexp_like(c.c_email_address, '.*@example\\.com') THEN 'ExampleDomain'
            ELSE 'OtherDomain'
        END AS email_domain_category,
        ARRAY[hd.hd_buy_potential, c.c_salutation] AS info_array
    FROM
        customer c
    FULL OUTER JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_email_address LIKE '%@%'
),
expanded AS (
    SELECT
        b.*,
        u.value AS info_element
    FROM
        base b
    CROSS JOIN UNNEST(b.info_array) AS u(value)
)
SELECT
    e.c_customer_sk,
    MAX(e.c_first_name) AS first_name,
    MAX(e.c_last_name) AS last_name,
    CONCAT(MAX(e.c_first_name), ' ', MAX(e.c_last_name)) AS full_name,
    MAX(e.c_email_address) AS email_address,
    REGEXP_EXTRACT(MAX(e.c_email_address), '@(.+)$', 1) AS email_domain,
    MAX(e.email_domain_category) AS email_domain_category,
    e.info_element,
    COUNT(wr.wr_return_quantity) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(CASE WHEN wr.wr_fee > 50 THEN wr.wr_fee ELSE 0 END) AS high_fee_sum,
    SUM(CASE WHEN wr.wr_fee > 50 THEN 1 ELSE 0 END) AS high_fee_count
FROM
    expanded e
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = e.c_customer_sk
WHERE
    EXISTS (
        SELECT 1
        FROM web_returns w2
        WHERE w2.wr_refunded_customer_sk = e.c_customer_sk
          AND w2.wr_fee > 20
    )
    AND REGEXP_LIKE(e.info_element, '^[0-9]+')
GROUP BY CUBE (e.c_customer_sk, e.email_domain_category, e.info_element)
HAVING COUNT(wr.wr_return_quantity) > 0
ORDER BY total_return_amount DESC
LIMIT 100
