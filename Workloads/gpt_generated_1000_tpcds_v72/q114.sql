WITH per_customer AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        CASE WHEN hd.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END AS vehicle_status
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND cd.cd_education_status = 'Advanced Degree'
      AND hd.hd_buy_potential = '>10000'
      AND ca.ca_country = 'United States'
      AND wr.wr_return_amt > 100
    GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_vehicle_count
)
SELECT
    vehicle_status,
    cd_gender,
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(return_cnt) AS total_returns,
    COUNT(*) AS num_customers
FROM per_customer
GROUP BY vehicle_status, cd_gender
HAVING AVG(total_return_amt) > 500
ORDER BY avg_total_return_amt DESC
LIMIT 100
