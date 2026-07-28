WITH agg_per_customer AS (
    SELECT
        c.c_customer_sk,
        c.c_first_shipto_date_sk AS first_shipto_date_sk,
        COUNT(*) AS page_cnt,
        SUM(wp.wp_char_count) AS total_char,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_image_count) AS avg_images
    FROM tpcds.customer c
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_first_shipto_date_sk BETWEEN 2449000 AND 2452000
      AND c.c_first_sales_date_sk IN (2450394, 2452341, 2449215)
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_rec_start_date >= DATE '1999-09-04'
      AND wp.wp_rec_end_date <= DATE '2001-09-02'
      AND wp.wp_type IN ('home', 'product', 'search')
    GROUP BY c.c_customer_sk, c.c_first_shipto_date_sk
)
SELECT
    first_shipto_date_sk,
    COUNT(*) AS num_customers,
    SUM(page_cnt) AS total_pages,
    AVG(total_char) AS avg_char_per_customer,
    SUM(total_links) AS total_links_all
FROM agg_per_customer
WHERE total_char > 0
  AND total_links >= 10
GROUP BY first_shipto_date_sk
HAVING COUNT(*) >= 5
ORDER BY avg_char_per_customer DESC
LIMIT 10
