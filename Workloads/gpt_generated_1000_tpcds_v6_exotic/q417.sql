WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        REGEXP_EXTRACT(MIN(c.c_email_address), '@(.+)$') AS email_domain,
        CONCAT(MIN(c.c_first_name), ' ', MIN(c.c_last_name)) AS sample_customer_full_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        REGEXP_LIKE(s.s_store_name, 'Market')
        AND c.c_email_address LIKE '%@example.com'
        AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.d_year,
    a.total_sales,
    a.distinct_customers,
    a.email_domain,
    a.sample_customer_full_name,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY a.d_year DESC, a.total_sales DESC
LIMIT 100
