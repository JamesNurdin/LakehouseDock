WITH sales_data AS (
    SELECT
        s.s_store_name,
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_discount_amt,
        c.c_customer_sk,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND s.s_country = 'United States'
      AND s.s_street_type = 'Court'
      AND d.d_year = 2020
      AND d.d_moy = 5
      AND hd.hd_income_band_sk = 3
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    COUNT(*) AS txn_count,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_net_paid_inc_tax) AS total_sales,
    AVG(ss_ext_discount_amt) AS avg_discount,
    MIN(ss_net_paid_inc_tax) AS min_sale,
    MAX(ss_net_paid_inc_tax) AS max_sale
FROM sales_data
GROUP BY s_store_name, d_year, d_month_seq
ORDER BY total_sales DESC
LIMIT 100
