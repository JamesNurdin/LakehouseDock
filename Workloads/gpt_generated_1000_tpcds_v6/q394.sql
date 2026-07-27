/*
Goal: Compute, for each customer birth year, the average store‑return amount (including tax) and related activity metrics, only for customers that have at least one product‑type web page. The query first aggregates per‑customer data (including possible missing returns or web pages via LEFT OUTER JOINs), then performs a higher‑level aggregation with a HAVING clause that compares each birth‑year average to the overall average.
*/
WITH per_customer AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        COALESCE(SUM(sr.sr_return_amt_inc_tax), 0)               AS total_return_inc_tax,
        COUNT(sr.sr_ticket_number)                               AS return_cnt,
        COALESCE(SUM(wp.wp_max_ad_count), 0)                     AS total_max_ad,
        COUNT(DISTINCT wp.wp_web_page_sk)                        AS web_page_cnt
    FROM
        customer c
        LEFT JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
        LEFT JOIN store_returns sr
            ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 1990                     -- predicate 1
        AND c.c_current_addr_sk > 1000000                         -- predicate 2
        AND (sr.sr_reversed_charge IS NULL OR sr.sr_reversed_charge > 100) -- predicate 3
        AND (wp.wp_max_ad_count IS NULL OR wp.wp_max_ad_count <= 3)          -- predicate 4
        AND wp.wp_rec_start_date >= DATE '1999-01-01'            -- predicate 5 (date column)
        AND wp.wp_rec_start_date <= DATE '2001-12-31'            -- predicate 6
    GROUP BY
        c.c_customer_sk,
        c.c_birth_year
)
SELECT
    pc.c_birth_year,
    AVG(pc.total_return_inc_tax)               AS avg_return_inc_tax,
    SUM(pc.return_cnt)                         AS total_returns,
    SUM(pc.total_max_ad)                       AS total_max_ad,
    COUNT(*)                                   AS customers_in_year
FROM
    per_customer pc
WHERE
    EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = pc.c_customer_sk
          AND wp2.wp_type = 'product'
    )
GROUP BY
    pc.c_birth_year
HAVING
    AVG(pc.total_return_inc_tax) > (
        SELECT AVG(total_return_inc_tax) FROM per_customer
    )
ORDER BY
    avg_return_inc_tax DESC
LIMIT 100
