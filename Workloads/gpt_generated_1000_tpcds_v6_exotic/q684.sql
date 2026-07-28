WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)', 1) AS email_domain,
        c.c_login,
        c.c_last_review_date,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        substr(c.c_first_name, 1, 1) || substr(c.c_last_name, 1, 1) AS initials,
        row_number() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY c.c_last_review_date DESC) AS review_rank
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(c.c_email_address, '@.*\\.com$')
      AND c.c_login LIKE 'A%'
)
SELECT
    c_customer_id,
    email_domain,
    initials,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    review_rank
FROM (
    SELECT
        c_customer_id,
        email_domain,
        initials,
        hd_buy_potential,
        ib_lower_bound,
        ib_upper_bound,
        review_rank
    FROM base
    WHERE hd_buy_potential = '>10000'
) 
UNION ALL
SELECT
    c_customer_id,
    email_domain,
    initials,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    review_rank
FROM base
WHERE hd_buy_potential = '0-500'
ORDER BY review_rank ASC, c_customer_id
LIMIT 100
