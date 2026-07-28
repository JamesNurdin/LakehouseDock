/*
Goal: Analyse store return transactions together with customer, demographic, store and web page information, separating high‑value and low‑value returns, applying a semi‑join filter, adding a row number window function, and limiting to the latest 100 rows.
*/
WITH base_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_store_sk,
        sr.sr_return_time_sk,
        t.t_hour,
        t.t_meal_time,
        s.s_store_name,
        s.s_state,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM store_returns sr
    JOIN time_dim t        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s           ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
),
sub_high AS (
    SELECT
        br.sr_returned_date_sk,
        br.sr_return_amt_inc_tax,
        br.sr_return_quantity,
        br.t_hour,
        br.t_meal_time,
        br.s_store_name,
        br.s_state,
        br.cd_gender,
        br.cd_credit_rating,
        c.c_customer_id,
        c.c_first_name,
        c.c_birth_country,
        cd_cur.cd_credit_rating AS cur_credit_rating,
        wp1.wp_url AS wp_url_1,
        wp2.wp_url AS wp_url_2,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY br.sr_returned_date_sk DESC) AS rn
    FROM base_returns br
    JOIN customer c               ON br.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd_cur ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
    JOIN web_page wp1            ON wp1.wp_customer_sk = c.c_customer_sk
    JOIN web_page wp2            ON wp2.wp_customer_sk = c.c_customer_sk
    JOIN store s2                ON br.sr_store_sk = s2.s_store_sk
    JOIN time_dim t2             ON br.sr_return_time_sk = t2.t_time_sk
    WHERE br.sr_return_amt_inc_tax > 100
      AND EXISTS (
            SELECT 1 FROM web_page wp_check
            WHERE wp_check.wp_customer_sk = c.c_customer_sk
              AND wp_check.wp_type = 'product'
        )
),
sub_low AS (
    SELECT
        br.sr_returned_date_sk,
        br.sr_return_amt_inc_tax,
        br.sr_return_quantity,
        br.t_hour,
        br.t_meal_time,
        br.s_store_name,
        br.s_state,
        br.cd_gender,
        br.cd_credit_rating,
        c.c_customer_id,
        c.c_first_name,
        c.c_birth_country,
        cd_cur.cd_credit_rating AS cur_credit_rating,
        wp1.wp_url AS wp_url_1,
        wp2.wp_url AS wp_url_2,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY br.sr_returned_date_sk DESC) AS rn
    FROM base_returns br
    JOIN customer c               ON br.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd_cur ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
    JOIN web_page wp1            ON wp1.wp_customer_sk = c.c_customer_sk
    JOIN web_page wp2            ON wp2.wp_customer_sk = c.c_customer_sk
    JOIN store s2                ON br.sr_store_sk = s2.s_store_sk
    JOIN time_dim t2             ON br.sr_return_time_sk = t2.t_time_sk
    WHERE br.sr_return_amt_inc_tax <= 100
      AND c.c_birth_country IN ('JAPAN', 'HUNGARY')
)
SELECT *
FROM sub_high
UNION ALL
SELECT *
FROM sub_low
ORDER BY sr_returned_date_sk DESC
LIMIT 100
