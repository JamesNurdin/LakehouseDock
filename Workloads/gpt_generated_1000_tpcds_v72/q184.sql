SELECT
    MIN(CONCAT(s.s_store_name, ' - ', CAST(ib.ib_income_band_sk AS VARCHAR))) AS store_income_label,
    s.s_store_name,
    ib.ib_income_band_sk,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High'
        WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS avg_unit_price
FROM
    store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_url LIKE '%foo.com%'
          AND regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) = 'www.foo.com'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
    )
GROUP BY
    GROUPING SETS (
        (s.s_store_name, ib.ib_income_band_sk),
        (s.s_store_name),
        ()
    )
ORDER BY total_sales DESC
LIMIT 100
