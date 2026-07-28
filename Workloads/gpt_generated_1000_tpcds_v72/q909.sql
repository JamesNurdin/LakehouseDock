/*
Goal: Combine customers who have auto‑generated web pages with those who have manually created pages, showing the number of distinct pages per customer, an activity level derived from the count, and the most recent review date (via a correlated scalar subquery). The result is ordered by activity level and customer ID.
*/
WITH y_pages AS (
    SELECT
        cust.c_customer_id,
        cust.c_salutation,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        CASE WHEN COUNT(DISTINCT wp.wp_web_page_sk) > 5 THEN 'High' ELSE 'Low' END AS activity_level,
        (
            SELECT MAX(c2.c_last_review_date)
            FROM customer c2
            WHERE c2.c_customer_sk = cust.c_customer_sk
        ) AS last_review_date
    FROM web_page wp
    JOIN customer cust
        ON wp.wp_customer_sk = cust.c_customer_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND wp.wp_access_date_sk BETWEEN 2452550 AND 2452600
      AND cust.c_birth_year > 1970
      AND EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_customer_sk = cust.c_customer_sk
            AND wp2.wp_link_count > 10
      )
    GROUP BY cust.c_customer_id, cust.c_salutation, cust.c_customer_sk
),

n_pages AS (
    SELECT
        cust.c_customer_id,
        cust.c_salutation,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        CASE WHEN COUNT(DISTINCT wp.wp_web_page_sk) > 3 THEN 'High' ELSE 'Low' END AS activity_level,
        (
            SELECT MAX(c2.c_last_review_date)
            FROM customer c2
            WHERE c2.c_customer_sk = cust.c_customer_sk
        ) AS last_review_date
    FROM web_page wp
    JOIN customer cust
        ON wp.wp_customer_sk = cust.c_customer_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_access_date_sk BETWEEN 2452620 AND 2452650
      AND cust.c_birth_month = 5
    GROUP BY cust.c_customer_id, cust.c_salutation, cust.c_customer_sk
)

SELECT *
FROM (
    SELECT c_customer_id, c_salutation, page_cnt, activity_level, last_review_date
    FROM y_pages
    UNION ALL
    SELECT c_customer_id, c_salutation, page_cnt, activity_level, last_review_date
    FROM n_pages
) AS combined
ORDER BY activity_level DESC, c_customer_id
