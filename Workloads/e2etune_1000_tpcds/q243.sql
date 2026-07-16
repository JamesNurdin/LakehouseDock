WITH catalog_stats AS (
    SELECT
        'catalog' AS channel,
        cr.cr_returned_date_sk AS return_date_sk,
        sm.sm_ship_mode_id AS ship_mode,
        rc.c_preferred_cust_flag AS returning_preferred_flag,
        rf.c_preferred_cust_flag AS refunded_preferred_flag,
        COUNT(*) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer rc ON cr.cr_returning_customer_sk = rc.c_customer_sk
    JOIN customer rf ON cr.cr_refunded_customer_sk = rf.c_customer_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451200
    GROUP BY cr.cr_returned_date_sk, sm.sm_ship_mode_id, rc.c_preferred_cust_flag, rf.c_preferred_cust_flag
),
web_stats AS (
    SELECT
        'web' AS channel,
        wr.wr_returned_date_sk AS return_date_sk,
        NULL AS ship_mode,
        rc.c_preferred_cust_flag AS returning_preferred_flag,
        rf.c_preferred_cust_flag AS refunded_preferred_flag,
        COUNT(*) AS num_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN customer rc ON wr.wr_returning_customer_sk = rc.c_customer_sk
    JOIN customer rf ON wr.wr_refunded_customer_sk = rf.c_customer_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451200
    GROUP BY wr.wr_returned_date_sk, rc.c_preferred_cust_flag, rf.c_preferred_cust_flag
)
SELECT
    channel,
    return_date_sk,
    ship_mode,
    returning_preferred_flag,
    refunded_preferred_flag,
    num_returns,
    total_net_loss,
    total_return_amount,
    avg_return_quantity,
    RANK() OVER (PARTITION BY return_date_sk, channel ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT * FROM catalog_stats
    UNION ALL
    SELECT * FROM web_stats
) AS combined
ORDER BY return_date_sk, channel, net_loss_rank
LIMIT 200
