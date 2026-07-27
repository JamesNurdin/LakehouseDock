WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(wr.wr_net_loss) > 1000 THEN 'HIGH'
            WHEN SUM(wr.wr_net_loss) > 100  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category,
        regexp_extract(c.c_email_address, '@([^\\.]+\\..+)$', 1) AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND c.c_birth_country = 'United States'
    GROUP BY
        c.c_customer_id,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        regexp_extract(c.c_email_address, '@([^\\.]+\\..+)$', 1),
        concat(c.c_first_name, ' ', c.c_last_name)
),
distinct_base AS (
    SELECT DISTINCT * FROM base
)
SELECT
    db.c_customer_id,
    substring(db.c_customer_id, 1, 5) AS cust_id_prefix,
    db.full_name,
    db.email_domain,
    db.ib_lower_bound,
    db.ib_upper_bound,
    db.total_net_loss,
    db.return_cnt,
    db.loss_category,
    ROW_NUMBER() OVER (PARTITION BY db.ib_upper_bound ORDER BY db.total_net_loss DESC) AS rank_within_income_band
FROM distinct_base db
WHERE db.loss_category <> 'LOW'
ORDER BY db.total_net_loss DESC
LIMIT 100
