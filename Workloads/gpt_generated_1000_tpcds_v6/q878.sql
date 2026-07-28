WITH returns_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN store s
        ON d.d_date_sk = s.s_closed_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_manufact_id IN (117, 479, 260)
      AND s.s_state IN ('CA', 'TX', 'NY')
      AND d.d_fy_quarter_seq = 19
    GROUP BY d.d_year, i.i_category, s.s_state
)
SELECT
    d_year,
    i_category,
    s_state,
    total_return_amt,
    return_cnt,
    RANK() OVER (PARTITION BY i_category ORDER BY total_return_amt DESC) AS category_return_rank,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_return_amt ASC) AS state_return_rownum
FROM returns_agg
ORDER BY total_return_amt DESC, d_year
LIMIT 100
