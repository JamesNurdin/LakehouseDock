WITH returns_by_page_month AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_url,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        MAX(cc.cc_city) AS closed_city
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d_ret.d_date_sk
    GROUP BY wp.wp_web_page_id, wp.wp_url, d_ret.d_year, d_ret.d_month_seq
)
SELECT *
FROM (
    SELECT
        wp_web_page_id,
        wp_url,
        d_year,
        d_month_seq,
        total_return_amt,
        return_cnt,
        closed_city,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_return_amt DESC) AS month_rank,
        SUM(total_return_amt) OVER (PARTITION BY d_year, d_month_seq ORDER BY total_return_amt DESC ROWS UNBOUNDED PRECEDING) AS cumulative_return_amt,
        CASE
            WHEN total_return_amt > 5000 THEN 'High'
            WHEN total_return_amt BETWEEN 2000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM returns_by_page_month
) t
WHERE month_rank <= 3
ORDER BY d_year, d_month_seq, month_rank
