WITH refunded_agg AS (
    SELECT
        ca_ref.ca_state AS state,
        cd_ref.cd_gender AS gender,
        td.t_hour AS hour,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt,
        MIN(wr.wr_return_ship_cost) AS min_ship_cost,
        MAX(wr.wr_return_ship_cost) AS max_ship_cost,
        'Refunded' AS src
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer cust_ref
        ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_hour = 14
      AND cust_ref.c_birth_month = 5
      AND ib.ib_lower_bound >= 50000
    GROUP BY ca_ref.ca_state, cd_ref.cd_gender, td.t_hour
),
returning_agg AS (
    SELECT
        ca_ref.ca_state AS state,
        cd_ref.cd_gender AS gender,
        td.t_hour AS hour,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt,
        MIN(wr.wr_return_ship_cost) AS min_ship_cost,
        MAX(wr.wr_return_ship_cost) AS max_ship_cost,
        'Returning' AS src
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer cust_ret
        ON wr.wr_returning_customer_sk = cust_ret.c_customer_sk
    JOIN customer_address ca_ref
        ON wr.wr_returning_addr_sk = ca_ref.ca_address_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_returning_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON wr.wr_returning_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_hour = 9
      AND cust_ret.c_birth_month = 2
      AND ib.ib_upper_bound <= 80000
    GROUP BY ca_ref.ca_state, cd_ref.cd_gender, td.t_hour
)
SELECT * FROM refunded_agg
UNION ALL
SELECT * FROM returning_agg
ORDER BY total_return_amt DESC
LIMIT 100
