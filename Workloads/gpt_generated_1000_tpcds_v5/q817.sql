WITH returns_with_date AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_web_page_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        d.d_year,
        d.d_dow,
        d.d_holiday,
        d.d_date
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND d.d_dow = 4
      AND d.d_holiday = 'N'
)
SELECT
    rd.d_year,
    COALESCE(wp.wp_type, 'UNKNOWN') AS page_type,
    SUM(rd.wr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(rd.wr_return_amt_inc_tax) AS avg_return_inc_tax,
    COUNT(*) AS return_cnt,
    MAX(rd.wr_return_amt_inc_tax) AS max_return,
    MIN(rd.wr_return_amt_inc_tax) AS min_return,
    CASE WHEN SUM(rd.wr_return_amt_inc_tax) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
    (SELECT AVG(wr2.wr_return_amt_inc_tax) FROM web_returns wr2) AS overall_avg_return
FROM returns_with_date rd
LEFT JOIN web_page wp
  ON rd.wr_web_page_sk = wp.wp_web_page_sk
  AND wp.wp_autogen_flag = 'N'
WHERE rd.wr_return_amt_inc_tax > 1000
GROUP BY rd.d_year, COALESCE(wp.wp_type, 'UNKNOWN')
ORDER BY total_return_inc_tax DESC
LIMIT 100
