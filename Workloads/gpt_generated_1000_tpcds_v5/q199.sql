WITH return_agg AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        COUNT(*) AS cnt_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        MIN(wr.wr_return_amt) AS min_return_amt,
        MAX(wr.wr_return_amt) AS max_return_amt
    FROM web_returns AS wr
    JOIN date_dim AS d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page AS wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store AS s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count > 4
    GROUP BY s.s_store_sk, s.s_state, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    ra.s_store_sk,
    ra.s_state,
    ra.d_year,
    ra.d_month_seq,
    ra.cnt_returns,
    ra.total_return_amt,
    ra.avg_return_qty,
    ra.min_return_amt,
    ra.max_return_amt
FROM return_agg AS ra
WHERE ra.total_return_amt > 1000
  AND EXISTS (
        SELECT 1
        FROM store AS s2
        WHERE s2.s_store_sk = ra.s_store_sk
          AND s2.s_tax_percentage > 5.00
    )
ORDER BY ra.total_return_amt DESC
LIMIT 100
