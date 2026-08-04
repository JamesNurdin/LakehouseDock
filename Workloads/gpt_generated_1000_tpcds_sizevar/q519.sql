WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_login,
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_store_credit,
        d.d_date,
        d.d_year,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        LAG(sr.sr_return_amt) OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date) AS prev_return_amt
    FROM customer c
    FULL OUTER JOIN store_returns sr
        ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    jd.c_customer_id,
    jd.c_first_name || ' ' || jd.c_last_name AS full_name,
    jd.d_date AS return_date,
    jd.sr_item_sk,
    jd.sr_return_amt,
    jd.prev_return_amt,
    CASE WHEN jd.sr_store_credit > 100 THEN 'High' ELSE 'Low' END AS credit_category,
    CASE WHEN jd.sr_return_amt > (SELECT MAX(sr_return_amt) FROM store_returns) THEN 'MAX' ELSE 'NORMAL' END AS return_flag,
    jd.ib_lower_bound,
    jd.ib_upper_bound,
    regexp_extract(jd.c_email_address, '^([^@]+)@', 1) AS email_local_part,
    CASE WHEN regexp_like(jd.c_login, '^[A-Z]{2}[0-9]{4}$') THEN 'PatternMatch' ELSE 'Other' END AS login_pattern
FROM joined_data jd
WHERE jd.c_email_address IS NOT NULL
  AND regexp_like(jd.c_email_address, '@example\\.com$')
  AND jd.d_year = 2001

UNION DISTINCT

SELECT
    CAST(NULL AS varchar) AS c_customer_id,
    CAST(NULL AS varchar) AS full_name,
    CAST(NULL AS date)    AS return_date,
    CAST(NULL AS integer) AS sr_item_sk,
    SUM(jd2.sr_return_amt) AS sr_return_amt,
    CAST(NULL AS double)  AS prev_return_amt,
    CASE WHEN SUM(jd2.sr_store_credit) > 5000 THEN 'High' ELSE 'Low' END AS credit_category,
    CASE WHEN SUM(jd2.sr_return_amt) > (SELECT MAX(sr_return_amt) FROM store_returns) THEN 'MAX' ELSE 'NORMAL' END AS return_flag,
    jd2.ib_lower_bound,
    jd2.ib_upper_bound,
    CAST(NULL AS varchar) AS email_local_part,
    CASE WHEN regexp_like(jd2.hd_buy_potential, '^High.*') THEN 'PatternMatch' ELSE 'Other' END AS login_pattern
FROM joined_data jd2
WHERE jd2.hd_buy_potential IS NOT NULL
GROUP BY jd2.ib_lower_bound, jd2.ib_upper_bound, jd2.hd_buy_potential

ORDER BY sr_return_amt DESC
LIMIT 100
