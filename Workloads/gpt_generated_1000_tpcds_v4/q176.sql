WITH filtered_sales AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_sales_price,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk
    FROM store_sales ss
    WHERE ss.ss_net_paid_inc_tax > 500
      AND ss.ss_sold_time_sk IN (35137, 45944, 65446)
)
SELECT
    s.s_store_id,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    MIN(fs.ss_net_paid_inc_tax) AS min_net_paid,
    MAX(fs.ss_net_paid_inc_tax) AS max_net_paid
FROM filtered_sales fs
JOIN customer c
    ON fs.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON fs.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON fs.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_web_page_id = 'AAAAAAAADBAAAAAA'
  AND wp.wp_access_date_sk BETWEEN 2452555 AND 2452607
  AND cd.cd_gender = 'M'
  AND ib.ib_upper_bound >= 50000
  AND s.s_company_id = 1
  AND cd.cd_purchase_estimate > (
        SELECT AVG(cd2.cd_purchase_estimate)
        FROM customer_demographics cd2
    )
GROUP BY
    s.s_store_id,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING
    SUM(fs.ss_ext_sales_price) > 10000
    AND COUNT(DISTINCT c.c_customer_sk) >= 5
ORDER BY total_sales DESC
LIMIT 100
