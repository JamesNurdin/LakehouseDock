WITH
    filtered_returns AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_returned_time_sk,
            wr.wr_return_amt_inc_tax,
            wr.wr_net_loss,
            wr.wr_refunded_customer_sk,
            wr.wr_refunded_cdemo_sk,
            wr.wr_refunded_addr_sk
        FROM web_returns wr
        WHERE wr.wr_return_amt_inc_tax > 500
          AND wr.wr_net_loss > 0
    ),
    joined_data AS (
        SELECT
            wr.wr_returned_time_sk,
            t.t_hour,
            t.t_minute,
            c.c_customer_id,
            c.c_birth_year,
            cd.cd_gender,
            ca.ca_state,
            ca.ca_location_type,
            wr.wr_return_amt_inc_tax,
            wr.wr_net_loss
        FROM filtered_returns wr
        JOIN time_dim t
          ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN customer c
          ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
          ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca
          ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE t.t_hour BETWEEN 8 AND 17
          AND c.c_birth_year BETWEEN 1960 AND 1975
          AND ca.ca_location_type = 'condo'
    ),
    aggregated AS (
        SELECT
            c_customer_id,
            t_hour,
            ca_state,
            cd_gender,
            SUM(wr_return_amt_inc_tax) AS total_return_amt,
            SUM(wr_net_loss) AS total_net_loss,
            COUNT(*) AS cnt_returns
        FROM joined_data
        GROUP BY CUBE (c_customer_id, t_hour, ca_state, cd_gender)
    ),
    ranked AS (
        SELECT
            c_customer_id,
            t_hour,
            ca_state,
            cd_gender,
            total_return_amt,
            total_net_loss,
            cnt_returns,
            RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
        FROM aggregated
        WHERE total_net_loss IS NOT NULL
    ),
    high_loss_customers AS (
        SELECT c_customer_id
        FROM ranked
        WHERE net_loss_rank <= 50
    ),
    low_loss_customers AS (
        SELECT c_customer_id
        FROM ranked
        WHERE total_net_loss < 1000
    )
SELECT
    r.c_customer_id,
    r.t_hour,
    r.ca_state,
    r.cd_gender,
    r.total_return_amt,
    r.total_net_loss,
    r.cnt_returns,
    r.net_loss_rank
FROM ranked r
WHERE r.c_customer_id IN (
    SELECT c_customer_id FROM high_loss_customers
    INTERSECT
    SELECT c_customer_id FROM low_loss_customers
)
ORDER BY r.net_loss_rank
LIMIT 100
