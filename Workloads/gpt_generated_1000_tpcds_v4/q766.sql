WITH sales_filtered AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        d.d_year,
        d.d_month_seq,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
      AND regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{2}')
)
SELECT
    CONCAT(s.c_first_name, ' ', s.c_last_name) AS full_name,
    s.ss_customer_sk AS customer_sk,
    SUM(s.ss_net_paid) AS total_net_paid,
    REGEXP_EXTRACT(s.i_item_desc, '([A-Z]{2}[0-9]{2})', 1) AS extracted_code,
    MIN(s.d_year) AS year,
    MIN(s.d_month_seq) AS month_seq,
    MIN(s.ib_lower_bound) AS income_lower,
    MAX(s.ib_upper_bound) AS income_upper
FROM sales_filtered s
GROUP BY
    s.c_first_name,
    s.c_last_name,
    s.ss_customer_sk,
    s.i_item_desc
ORDER BY total_net_paid DESC
LIMIT 100
