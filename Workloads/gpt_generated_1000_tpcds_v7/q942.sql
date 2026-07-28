WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        c.c_email_address,
        d.d_year,
        d.d_weekend,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2020
      AND d.d_weekend = 'Y'
      AND regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND s.s_store_name LIKE 'Store%'
)
SELECT
    s_store_name,
    ib_lower_bound,
    ib_upper_bound,
    d_year,
    sum(ss_net_profit) AS total_net_profit,
    count(DISTINCT ss_customer_sk) AS unique_customers,
    concat(s_store_name, ' - ', cast(d_year AS varchar)) AS store_year_label,
    regexp_extract(c_email_address, '@([^.]*)\\.', 1) AS email_domain
FROM filtered_sales
GROUP BY
    s_store_name,
    ib_lower_bound,
    ib_upper_bound,
    d_year,
    regexp_extract(c_email_address, '@([^.]*)\\.', 1)
ORDER BY total_net_profit DESC
LIMIT 100
