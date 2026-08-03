WITH filtered_returns AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_store_sk,
        sr.sr_refunded_cash,
        c.c_email_address,
        substring(c.c_email_address, 1, position('@' IN c.c_email_address) - 1) AS email_user,
        regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1) AS email_domain
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.+@gmail\\.com$')
      AND c.c_email_address LIKE '%@gmail.com'
)
SELECT
    t.t_hour AS hour_of_day,
    COUNT(*) AS total_returns,
    SUM(fr.sr_refunded_cash) AS total_refunded_cash,
    MAX(concat('User:', fr.email_user)) AS sample_user_prefix
FROM filtered_returns fr
JOIN time_dim t
    ON fr.sr_return_time_sk = t.t_time_sk
JOIN store s
    ON fr.sr_store_sk = s.s_store_sk
GROUP BY t.t_hour
HAVING SUM(fr.sr_refunded_cash) > 1000
ORDER BY total_refunded_cash DESC
