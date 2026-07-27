WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_current_year = 'Y'
)
SELECT
    ws.web_manager,
    ws.web_name,
    regexp_extract(ws.web_name, '(\\w+)') AS first_word,
    fd.d_year,
    SUM(wr.wr_return_amt) AS total_return_amt,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
        JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = fd.d_year
    ) AS avg_year_return_amt
FROM web_returns wr
JOIN filtered_dates fd ON wr.wr_returned_date_sk = fd.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = fd.d_date_sk
JOIN store s ON s.s_closed_date_sk = fd.d_date_sk
WHERE regexp_like(ws.web_manager, '^J.*n$')
  AND s.s_street_name LIKE '%Lee%'
GROUP BY
    ws.web_manager,
    ws.web_name,
    regexp_extract(ws.web_name, '(\\w+)'),
    fd.d_year
ORDER BY total_return_amt DESC
LIMIT 100
