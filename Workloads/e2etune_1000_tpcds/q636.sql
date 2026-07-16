WITH grouped AS (
    SELECT
        cc.c_birth_year AS returning_birth_year,
        cf.c_birth_year AS refunded_birth_year,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_fee) AS total_fee,
        AVG(wr.wr_return_quantity) AS avg_quantity
    FROM web_returns wr
    JOIN customer cc ON wr.wr_returning_customer_sk = cc.c_customer_sk
    JOIN customer cf ON wr.wr_refunded_customer_sk = cf.c_customer_sk
    WHERE cc.c_preferred_cust_flag = 'Y'
      AND cf.c_preferred_cust_flag = 'Y'
      AND cc.c_birth_year BETWEEN 1970 AND 1990
      AND cf.c_birth_year BETWEEN 1970 AND 1990
      AND wr.wr_returned_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY cc.c_birth_year, cf.c_birth_year
    HAVING COUNT(*) > 50
)
SELECT
    returning_birth_year,
    refunded_birth_year,
    num_returns,
    total_return_amount,
    total_net_loss,
    total_fee,
    avg_quantity,
    total_net_loss / NULLIF(SUM(total_net_loss) OVER (), 0) AS net_loss_share,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM grouped
ORDER BY total_net_loss DESC
LIMIT 100
