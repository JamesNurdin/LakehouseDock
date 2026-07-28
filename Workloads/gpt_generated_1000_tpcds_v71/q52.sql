WITH filtered AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_current_cdemo_sk,
        c.c_last_review_date,
        c.c_first_sales_date_sk,
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_link_count,
        wp.wp_access_date_sk
    FROM tpcds.customer c
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_current_cdemo_sk IN (502141, 707524)
      AND c.c_last_review_date > 2452500
      AND c.c_first_sales_date_sk BETWEEN 2450500 AND 2451200
      AND wp.wp_link_count >= 5
      AND wp.wp_access_date_sk NOT IN (2452574, 2452555)
      AND wp.wp_web_page_sk <> 6
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_type = 'advertisement'
      )
)
SELECT
    f.c_customer_sk,
    f.c_customer_id,
    f.c_current_cdemo_sk,
    f.c_last_review_date,
    f.c_first_sales_date_sk,
    f.wp_web_page_sk,
    f.wp_url,
    f.wp_type,
    f.wp_link_count,
    CASE
        WHEN f.wp_link_count > 15 THEN 'High'
        WHEN f.wp_link_count > 5 THEN 'Medium'
        ELSE 'Low'
    END AS link_category,
    SUM(f.wp_link_count) OVER (PARTITION BY f.c_customer_sk) AS total_links_per_customer,
    ROW_NUMBER() OVER (PARTITION BY f.c_customer_sk ORDER BY f.wp_link_count DESC) AS page_rank
FROM filtered f
ORDER BY total_links_per_customer DESC, f.c_customer_sk
LIMIT 100
