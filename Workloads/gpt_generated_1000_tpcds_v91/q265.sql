WITH agg_sales AS (
    SELECT
        ss_customer_sk,
        ss_cdemo_sk,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_net_paid) AS avg_net_paid,
        COUNT(*) AS sales_count,
        MAX(ss_sold_date_sk) AS max_sold_date_sk
    FROM store_sales
    WHERE ss_ext_list_price > 5000
      AND ss_ext_tax BETWEEN 5 AND 30
    GROUP BY ss_customer_sk, ss_cdemo_sk
),
filtered_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_birth_day,
        c_birth_year,
        c_last_review_date,
        c_current_cdemo_sk
    FROM customer
    WHERE c_birth_day = 15
      AND c_birth_year = 1975
      AND c_last_review_date > 2452360
)

SELECT
    c.c_customer_id,
    c.c_customer_sk,
    cd.cd_gender,
    cd.cd_credit_rating,
    wp.wp_url,
    agg.total_net_paid,
    agg.avg_net_paid,
    agg.sales_count,
    (SELECT AVG(ss_net_paid) FROM store_sales) AS overall_avg_net_paid,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY agg.max_sold_date_sk DESC) AS rn
FROM agg_sales agg
JOIN filtered_customers c
    ON agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_credit_rating = 'A'
  AND wp.wp_rec_end_date >= DATE '2000-09-02'
  AND wp.wp_url = 'http://www.foo.com'
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'home'
    )
GROUP BY c.c_customer_id, c.c_customer_sk, cd.cd_gender, cd.cd_credit_rating, wp.wp_url, agg.total_net_paid, agg.avg_net_paid, agg.sales_count, agg.max_sold_date_sk
HAVING agg.total_net_paid > 1000

UNION

SELECT
    c.c_customer_id,
    c.c_customer_sk,
    cd.cd_gender,
    cd.cd_credit_rating,
    wp.wp_url,
    agg.total_net_paid,
    agg.avg_net_paid,
    agg.sales_count,
    (SELECT AVG(ss_net_paid) FROM store_sales) AS overall_avg_net_paid,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY agg.max_sold_date_sk DESC) AS rn
FROM agg_sales agg
JOIN filtered_customers c
    ON agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_credit_rating = 'B'
  AND wp.wp_rec_end_date <= DATE '2001-09-02'
  AND wp.wp_url LIKE 'http://%foo.com'
  AND NOT EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'home'
    )
GROUP BY c.c_customer_id, c.c_customer_sk, cd.cd_gender, cd.cd_credit_rating, wp.wp_url, agg.total_net_paid, agg.avg_net_paid, agg.sales_count, agg.max_sold_date_sk
HAVING agg.sales_count >= 2

ORDER BY total_net_paid DESC
LIMIT 100
