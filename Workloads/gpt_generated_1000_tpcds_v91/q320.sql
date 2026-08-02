WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        d.d_year,
        t.t_hour,
        cc.cc_name,
        cc.cc_market_manager,
        cp.cp_department,
        cp.cp_type,
        sm.sm_type,
        cr.cr_return_amount,
        r.r_reason_desc,
        hd.hd_vehicle_count,
        ib.ib_lower_bound
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer bill_cust
        ON cs.cs_bill_customer_sk = bill_cust.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_year BETWEEN 2001 AND 2002
        AND cc.cc_market_manager IS NOT NULL
        AND cp.cp_type = 'C'
        AND sm.sm_type = 'AIR'
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 50000
        AND (r.r_reason_desc LIKE '%damage%' OR r.r_reason_desc IS NULL)
        AND cp.cp_catalog_page_sk IN (
            SELECT DISTINCT cs2.cs_catalog_page_sk
            FROM tpcds.catalog_sales cs2
            WHERE cs2.cs_quantity > 5
        )
        AND t.t_hour BETWEEN 8 AND 20
),
agg AS (
    SELECT
        cc_name,
        d_year,
        cp_department,
        SUM(cs_net_paid) AS total_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(cs_net_profit) AS total_profit
    FROM joined_data
    GROUP BY GROUPING SETS (
        (cc_name, d_year, cp_department),
        (cc_name, d_year),
        (cc_name),
        ()
    )
)
SELECT
    cc_name,
    CASE
        WHEN d_year IS NULL AND cp_department IS NULL THEN 'All Years & Departments'
        WHEN cp_department IS NULL THEN 'All Departments'
        ELSE 'Year ' || CAST(d_year AS VARCHAR) || ' Dept ' || cp_department
    END AS grouping_level,
    SUM(total_sales) AS sum_sales,
    AVG(total_sales) AS avg_sales,
    SUM(order_cnt) AS total_orders,
    SUM(total_profit) AS sum_profit
FROM agg
WHERE total_sales > 0
GROUP BY
    cc_name,
    CASE
        WHEN d_year IS NULL AND cp_department IS NULL THEN 'All Years & Departments'
        WHEN cp_department IS NULL THEN 'All Departments'
        ELSE 'Year ' || CAST(d_year AS VARCHAR) || ' Dept ' || cp_department
    END
HAVING SUM(total_sales) > 10000
ORDER BY sum_sales DESC
LIMIT 100
