WITH agg_returns AS (
    SELECT
        d.d_year AS year,
        c.c_preferred_cust_flag AS preferred_flag,
        p.p_promo_name AS promo_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_qty,
        COUNT(*) AS txn_count,
        CASE WHEN p.p_channel_dmail = 'Y' THEN 'DMail' ELSE 'Other' END AS promo_channel_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_dom BETWEEN 10 AND 20
      AND t.t_second IN (4, 16)
      AND p.p_channel_dmail = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        d.d_year,
        c.c_preferred_cust_flag,
        p.p_promo_name,
        CASE WHEN p.p_channel_dmail = 'Y' THEN 'DMail' ELSE 'Other' END
)
SELECT
    year,
    promo_channel_type,
    AVG(total_return_amt) AS avg_return_amt,
    SUM(total_qty) AS sum_qty,
    COUNT(*) AS num_groups
FROM agg_returns
GROUP BY year, promo_channel_type
HAVING AVG(total_return_amt) > 1000
ORDER BY avg_return_amt DESC
LIMIT 100
