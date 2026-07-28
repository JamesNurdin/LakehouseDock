WITH return_agg AS (
    SELECT
        cust.c_customer_id AS customer_id,
        d.d_year,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer cust
        ON wr.wr_returning_customer_sk = cust.c_customer_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND d.d_holiday = 'N'
        AND d.d_day_name = 'Monday'
        AND wr.wr_return_amt > 50
        AND wr.wr_reversed_charge BETWEEN 20 AND 300
        AND cust.c_salutation = 'Mrs.'
        AND EXISTS (
            SELECT 1
            FROM customer cref
            WHERE cref.c_customer_sk = wr.wr_refunded_customer_sk
              AND cref.c_preferred_cust_flag = 'Y'
        )
    GROUP BY cust.c_customer_id, d.d_year
)
SELECT DISTINCT
    agg.d_year,
    AVG(agg.total_return_amt) AS avg_return_amt,
    SUM(agg.total_net_loss) AS sum_net_loss,
    COUNT(*) AS customers_with_returns
FROM return_agg agg
GROUP BY agg.d_year
HAVING AVG(agg.total_return_amt) > 150
ORDER BY agg.d_year DESC
LIMIT 100
