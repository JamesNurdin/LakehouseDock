WITH customer_page_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(wp.wp_web_page_sk) AS page_count,
        SUM(wp.wp_max_ad_count) AS total_ad_count,
        AVG(wp.wp_char_count) AS avg_char_count,
        MAX(wp.wp_rec_start_date) AS latest_page_start
    FROM tpcds.customer c
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_last_review_date >= 2452380
      AND c.c_last_review_date <= 2452575
      AND wp.wp_max_ad_count > 0
      AND wp.wp_rec_start_date >= DATE '1998-01-01'
      AND wp.wp_type IN ('home', 'product')
      AND c.c_first_name NOT IN ('Amy')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked AS (
    SELECT
        cpa.*,  
        SUM(cpa.total_ad_count) OVER (PARTITION BY cpa.c_first_name) AS total_ad_by_first_name,
        RANK() OVER (ORDER BY cpa.total_ad_count DESC) AS ad_count_rank
    FROM customer_page_agg cpa
    WHERE cpa.page_count >= 2
      AND cpa.avg_char_count > 500
)
SELECT
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.page_count,
    r.total_ad_count,
    r.avg_char_count,
    r.latest_page_start,
    ROUND(r.total_ad_count * 1.0 / r.page_count, 2) AS avg_ad_per_page,
    r.total_ad_by_first_name,
    r.ad_count_rank
FROM ranked r
WHERE r.total_ad_by_first_name > 5
ORDER BY r.total_ad_count DESC, r.c_last_name
LIMIT 100
