WITH page_returns AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_creation_date_sk,
        d_ret.d_year,
        d_ret.d_quarter_seq,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt,
        REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/') AS domain
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wp.wp_url LIKE '%/promo%'
      AND REGEXP_LIKE(wp.wp_url, '\\.com')
      AND t.t_meal_time = 'Lunch'
      AND d_ret.d_year = 2001
    GROUP BY
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_creation_date_sk,
        d_ret.d_year,
        d_ret.d_quarter_seq,
        REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/')
)
SELECT
    pr.wp_web_page_sk,
    pr.wp_url,
    pr.wp_type,
    pr.domain,
    pr.d_year,
    pr.d_quarter_seq,
    pr.total_return_amt,
    pr.return_cnt,
    pr.avg_return_amt,
    SUBSTRING(pr.wp_type FROM 1 FOR 3) AS type_prefix,
    CASE
        WHEN pr.avg_return_amt > (SELECT AVG(wr_return_amt_inc_tax) FROM web_returns) THEN 'ABOVE_GLOBAL_AVG'
        ELSE 'BELOW_GLOBAL_AVG'
    END AS performance_flag
FROM page_returns pr
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
    WHERE wr2.wr_web_page_sk = pr.wp_web_page_sk
      AND d2.d_weekend = 'Y'
)
ORDER BY pr.avg_return_amt DESC
LIMIT 100
