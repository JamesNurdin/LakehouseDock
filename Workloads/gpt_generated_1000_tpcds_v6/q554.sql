WITH avg_return_by_date AS (
    SELECT d.d_date,
           AVG(wr.wr_return_amt) AS avg_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date
)
SELECT
    c.c_customer_id,
    d.d_date,
    SUM(wr.wr_return_amt) AS total_return_amt,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT ad.avg_return_amt FROM avg_return_by_date ad WHERE ad.d_date = d.d_date) AS avg_return_on_date
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND d.d_month_seq BETWEEN 1200 AND 1211
GROUP BY c.c_customer_id, d.d_date

UNION ALL

SELECT
    c.c_customer_id,
    d.d_date,
    SUM(wr.wr_return_amt) AS total_return_amt,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT ad.avg_return_amt FROM avg_return_by_date ad WHERE ad.d_date = d.d_date) AS avg_return_on_date
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'N'
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
          AND hd.hd_vehicle_count >= 2
      )
GROUP BY c.c_customer_id, d.d_date

ORDER BY total_return_amt DESC
LIMIT 100
