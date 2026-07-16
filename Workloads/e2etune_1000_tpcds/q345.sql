WITH cust_ret AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY sr.sr_customer_sk
),
store_demo_agg AS (
    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        cd_ret.cd_gender,
        cd_ret.cd_marital_status,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt) AS sum_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(sr.sr_return_quantity) AS total_quantity,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(CASE WHEN sr.sr_net_loss > 0 THEN 1 ELSE 0 END) AS loss_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_demographics cd_cust ON c.c_current_cdemo_sk = cd_cust.cd_demo_sk
    JOIN cust_ret cr ON sr.sr_customer_sk = cr.sr_customer_sk
    WHERE s.s_state IN ('CA', 'TX')
      AND cr.total_return_amt > 1000
      AND cd_cust.cd_education_status = 'College'
    GROUP BY
        s.s_store_name,
        s.s_city,
        s.s_state,
        cd_ret.cd_gender,
        cd_ret.cd_marital_status
)
SELECT
    sda.*,
    RANK() OVER (PARTITION BY sda.s_state ORDER BY sda.sum_return_amt DESC) AS store_state_rank
FROM store_demo_agg sda
ORDER BY sda.sum_return_amt DESC
LIMIT 100
