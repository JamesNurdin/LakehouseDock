/*
Goal: Identify each web page together with its author's name, creation and access dates, and character count. The query filters to pages created on non‑weekend days for customers born in selected months, only keeps customers that have at least one page larger than 5,000 characters, and then ranks the pages per customer by character count, creation date and recent access using window functions. A scalar subquery provides the total number of pages each customer owns.
*/
WITH page_info AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_creation_date_sk,
        wp.wp_access_date_sk,
        wp.wp_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        d_cre.d_date          AS creation_date,
        d_acc.d_date          AS access_date,
        d_cre.d_weekend       AS creation_weekend,
        d_acc.d_weekend       AS access_weekend
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_cre
        ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc
        ON wp.wp_access_date_sk = d_acc.d_date_sk
    WHERE
        wp.wp_type = 'Content'               -- predicate 1
        AND c.c_birth_month IN (4, 10, 12)    -- predicate 2
        AND d_cre.d_weekend = 'N'             -- predicate 3
)
SELECT
    pi.wp_web_page_id,
    pi.wp_url,
    pi.c_first_name,
    pi.c_last_name,
    pi.creation_date,
    pi.access_date,
    pi.wp_char_count,
    (
        SELECT COUNT(*)
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = pi.wp_customer_sk
    ) AS pages_per_customer,
    RANK() OVER (PARTITION BY pi.wp_customer_sk ORDER BY pi.wp_char_count DESC) AS char_count_rank,
    DENSE_RANK() OVER (PARTITION BY pi.wp_customer_sk ORDER BY pi.creation_date) AS creation_date_dense_rank,
    ROW_NUMBER() OVER (PARTITION BY pi.wp_customer_sk ORDER BY pi.access_date DESC) AS recent_access_rownum
FROM page_info pi
WHERE EXISTS (
    SELECT 1
    FROM web_page wp3
    WHERE wp3.wp_customer_sk = pi.wp_customer_sk
      AND wp3.wp_char_count > 5000
)
ORDER BY
    pi.c_last_name,
    char_count_rank
