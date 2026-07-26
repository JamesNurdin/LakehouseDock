WITH cust_txn AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_current_hdemo_sk,
        ss.ss_sold_date_sk,
        t.t_hour,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn,
        LAG(ss.ss_sold_date_sk) OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS prev_date,
        LAG(t.t_hour) OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS prev_hour
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
),
churn_calc AS (
    SELECT
        ct.c_customer_sk,
        ct.c_customer_id,
        ct.c_first_name,
        ct.c_last_name,
        ct.c_current_hdemo_sk,
        ct.ss_sold_date_sk AS latest_purchase_date,
        ct.prev_date AS previous_purchase_date,
        ct.t_hour AS latest_purchase_hour,
        ct.prev_hour AS previous_purchase_hour,
        CASE
            WHEN ct.prev_date IS NULL THEN 'New'
            WHEN ct.ss_sold_date_sk - ct.prev_date > 30 THEN 'At Risk'
            ELSE 'Active'
        END AS churn_status,
        ct.ss_sold_date_sk - ct.prev_date AS days_since_last_purchase,
        RANK() OVER (ORDER BY (ct.ss_sold_date_sk - ct.prev_date) DESC NULLS LAST) AS churn_rank
    FROM cust_txn ct
    WHERE ct.rn = 1
)
SELECT
    cc.c_customer_id,
    cc.c_first_name,
    cc.c_last_name,
    cc.latest_purchase_date,
    cc.previous_purchase_date,
    cc.days_since_last_purchase,
    cc.latest_purchase_hour,
    cc.previous_purchase_hour,
    cc.churn_status,
    cc.churn_rank,
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    hd.hd_dep_count
FROM churn_calc cc
LEFT JOIN household_demographics hd ON cc.c_current_hdemo_sk = hd.hd_demo_sk
ORDER BY cc.churn_rank
LIMIT 50
