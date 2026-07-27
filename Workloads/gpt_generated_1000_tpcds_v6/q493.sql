WITH daily_store_return AS (
    SELECT
        d.d_date,
        d.d_fy_year,
        ws.web_city,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE sr.sr_return_tax > 3.0
      AND sr.sr_customer_sk IN (11750971, 3852925, 9806179)
      AND d.d_fy_year = 1904
      AND d.d_dom BETWEEN 10 AND 21
      AND i.inv_quantity_on_hand > 100
      AND ws.web_city = 'Pleasant Hill'
    GROUP BY d.d_date, d.d_fy_year, ws.web_city
)
SELECT
    d_date,
    d_fy_year,
    web_city,
    total_return_amt,
    total_return_qty,
    return_cnt,
    SUM(total_return_amt) OVER (PARTITION BY web_city ORDER BY d_date) AS cum_return_amt_by_city,
    RANK() OVER (ORDER BY total_return_amt DESC) AS amt_rank
FROM daily_store_return
WHERE total_return_amt > (
    SELECT AVG(total_return_amt) FROM daily_store_return
)
ORDER BY total_return_amt DESC
LIMIT 100
