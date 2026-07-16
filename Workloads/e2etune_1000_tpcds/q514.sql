WITH aggregated_returns AS (
    SELECT
        rd.cd_gender AS returning_gender,
        rd.cd_marital_status AS returning_marital_status,
        fd.cd_gender AS refunded_gender,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer_demographics rd
        ON wr.wr_returning_cdemo_sk = rd.cd_demo_sk
    JOIN customer_demographics fd
        ON wr.wr_refunded_cdemo_sk = fd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND rd.cd_gender = 'F'
    GROUP BY rd.cd_gender,
             rd.cd_marital_status,
             fd.cd_gender
    HAVING SUM(wr.wr_return_amt) > 10000
)
SELECT
    returning_gender,
    returning_marital_status,
    refunded_gender,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    return_cnt,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    ROUND(100.0 * total_return_amount / SUM(total_return_amount) OVER (), 2) AS pct_of_total_return_amount
FROM aggregated_returns
ORDER BY total_return_amount DESC
LIMIT 50
