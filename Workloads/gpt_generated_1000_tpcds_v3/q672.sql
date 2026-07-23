WITH cc_filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cc.cc_employees,
        d_open.d_year AS open_year,
        d_open.d_month_seq AS open_month_seq,
        d_open.d_dow AS open_day_of_week,
        d_open.d_date_sk AS open_date_sk
    FROM call_center cc
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    WHERE cc.cc_state = 'CA'
      AND d_open.d_year = 1999
)

SELECT
    cc.cc_name,
    cc.cc_state,
    cd.cd_education_status,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(cc.cc_employees) AS total_employees,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    CASE
        WHEN cc.open_year = 1999 THEN 'Opened in 1999'
        ELSE 'Other Year'
    END AS open_year_category,
    MIN(d_sales.d_date) AS earliest_sales_date,
    MAX(d_sales.d_date) AS latest_sales_date
FROM cc_filtered cc
JOIN customer c
    ON c.c_first_sales_date_sk = cc.open_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
  AND d_sales.d_month_seq = 12
  AND EXISTS (
        SELECT 1
        FROM web_site ws
        JOIN date_dim d_ws
            ON ws.web_open_date_sk = d_ws.d_date_sk
        WHERE d_ws.d_date_sk = cc.open_date_sk
          AND ws.web_state = 'TX'
    )
GROUP BY
    cc.cc_name,
    cc.cc_state,
    cd.cd_education_status,
    cc.open_year
ORDER BY
    num_customers DESC,
    cc.cc_name
LIMIT 100
