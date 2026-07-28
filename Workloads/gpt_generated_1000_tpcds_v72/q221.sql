WITH base_agg AS (
    SELECT 
        cr.cr_returning_hdemo_sk AS returning_demo_sk,
        d.d_year,
        d.d_quarter_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001                       -- predicate 1
      AND d.d_qoy = 2                           -- predicate 2
      AND hd.hd_income_band_sk BETWEEN 2 AND 10 -- predicate 3
      AND hd.hd_vehicle_count >= 0             -- predicate 4
      AND cr.cr_return_quantity > 0            -- predicate 5
      AND cr.cr_fee < 10                        -- predicate 6
    GROUP BY cr.cr_returning_hdemo_sk, d.d_year, d.d_quarter_seq
)
SELECT 
    ba.returning_demo_sk,
    ba.d_year,
    ba.d_quarter_seq,
    ba.total_return_amount,
    wp_stats.max_link_count,
    wp_stats.page_cnt
FROM base_agg ba
JOIN tpcds.household_demographics hd
    ON hd.hd_demo_sk = ba.returning_demo_sk
CROSS JOIN LATERAL (
    SELECT 
        MAX(wp.wp_link_count) AS max_link_count,
        COUNT(*) AS page_cnt
    FROM tpcds.web_page wp
    JOIN tpcds.date_dim d_wp
        ON wp.wp_creation_date_sk = d_wp.d_date_sk
    WHERE d_wp.d_year = ba.d_year               -- align year with returns
      AND wp.wp_type = 'PRODUCT'                -- filter page type
      AND d_wp.d_month_seq = 5                  -- additional predicate
) wp_stats
WHERE EXISTS (
    SELECT 1
    FROM tpcds.web_page wp2
    JOIN tpcds.date_dim d2
        ON wp2.wp_access_date_sk = d2.d_date_sk
    WHERE d2.d_year = ba.d_year
      AND wp2.wp_type = 'PRODUCT'
      AND wp2.wp_link_count > 10
)
GROUP BY ba.returning_demo_sk, ba.d_year, ba.d_quarter_seq, ba.total_return_amount, wp_stats.max_link_count, wp_stats.page_cnt
HAVING SUM(ba.total_return_amount) > 1000
ORDER BY SUM(ba.total_return_amount) DESC
LIMIT 100
