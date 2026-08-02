WITH ss_agg AS (
    SELECT
        ss_customer_sk AS customer_sk,
        SUM(ss_net_paid) AS total_store_sales,
        COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451000 AND 2451100
      AND ss_quantity > 1
      AND ss_net_paid > 100
    GROUP BY ss_customer_sk
),
ws_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(*) AS web_sales_cnt,
        MIN(ws_web_page_sk) AS web_page_sk,
        MIN(ws_web_site_sk) AS web_site_sk,
        MAX(ws_ext_tax) AS max_ws_ext_tax
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451000 AND 2451100
      AND ws_coupon_amt > 10
      AND ws_ext_tax > 20
    GROUP BY ws_bill_customer_sk
),
r_agg AS (
    SELECT
        cr_returning_customer_sk AS customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        MAX(cr_return_amount) AS max_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
      AND cr.cr_return_amount > 500
      AND cr.cr_return_quantity > 0
    GROUP BY cr_returning_customer_sk
),
r_reason AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        MIN(r.r_reason_desc) AS return_reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_reason_sk = 12
    GROUP BY cr.cr_returning_customer_sk
),
wp_info AS (
    SELECT
        wp.wp_customer_sk AS customer_sk,
        MIN(wp.wp_type) AS wp_type,
        MAX(wp.wp_char_count) AS max_char_count
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
),
full_sales AS (
    SELECT
        COALESCE(ss.customer_sk, ws.customer_sk) AS customer_sk,
        ss.total_store_sales,
        ss.store_sales_cnt,
        ws.total_web_sales,
        ws.web_sales_cnt,
        ws.web_page_sk,
        ws.web_site_sk,
        ws.max_ws_ext_tax
    FROM ss_agg ss
    FULL OUTER JOIN ws_agg ws ON ss.customer_sk = ws.customer_sk
),
target_customers AS (
    SELECT DISTINCT cr.cr_returning_customer_sk AS customer_sk
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_reason_sk = 12
    UNION
    SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
    FROM web_sales ws
    WHERE ws.ws_net_paid > 1000
      AND ws.ws_coupon_amt > 50
    EXCEPT
    SELECT DISTINCT wp.wp_customer_sk AS customer_sk
    FROM web_page wp
    WHERE wp.wp_type = 'product'
      AND wp.wp_char_count > 2000
)
SELECT
    hd.hd_vehicle_count,
    COUNT(DISTINCT tc.customer_sk) AS cust_cnt,
    SUM(COALESCE(fs.total_store_sales, 0)) AS sum_store_sales,
    SUM(COALESCE(fs.total_web_sales, 0)) AS sum_web_sales,
    SUM(COALESCE(r_agg.total_return_amount, 0)) AS sum_return_amount,
    AVG(COALESCE(fs.total_store_sales, 0) + COALESCE(fs.total_web_sales, 0) - COALESCE(r_agg.total_return_amount, 0)) AS avg_net_spend,
    MIN(COALESCE(r_agg.max_return_amount, 0)) AS min_max_return_amount,
    MAX(fs.max_ws_ext_tax) AS max_ws_ext_tax,
    MIN(r_reason.return_reason_desc) AS example_return_reason,
    ws_site.web_name
FROM target_customers tc
LEFT JOIN full_sales fs ON tc.customer_sk = fs.customer_sk
LEFT JOIN r_agg ON tc.customer_sk = r_agg.customer_sk
LEFT JOIN r_reason ON tc.customer_sk = r_reason.customer_sk
LEFT JOIN customer c ON tc.customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN wp_info wp ON tc.customer_sk = wp.customer_sk
LEFT JOIN web_page wp_page ON fs.web_page_sk = wp_page.wp_web_page_sk
LEFT JOIN web_site ws_site ON fs.web_site_sk = ws_site.web_site_sk
GROUP BY hd.hd_vehicle_count, ws_site.web_name
HAVING COUNT(DISTINCT tc.customer_sk) > 5
ORDER BY sum_store_sales DESC
LIMIT 100
