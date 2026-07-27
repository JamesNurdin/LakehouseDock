WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_qty
    FROM tpcds.store_sales
    GROUP BY ss_store_sk, ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk
)
SELECT
    s.s_store_name,
    s.s_city,
    c.c_first_name,
    c.c_last_name,
    cd1.cd_gender,
    cd2.cd_education_status,
    hd1.hd_vehicle_count,
    hd2.hd_dep_count,
    sa.total_sales,
    sa.total_qty
FROM sales_agg sa
JOIN tpcds.customer c
    ON sa.ss_customer_sk = c.c_customer_sk
JOIN tpcds.store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN tpcds.customer_demographics cd1
    ON sa.ss_cdemo_sk = cd1.cd_demo_sk
JOIN tpcds.household_demographics hd1
    ON sa.ss_hdemo_sk = hd1.hd_demo_sk
JOIN tpcds.customer_demographics cd2
    ON c.c_current_cdemo_sk = cd2.cd_demo_sk
JOIN tpcds.household_demographics hd2
    ON c.c_current_hdemo_sk = hd2.hd_demo_sk
JOIN tpcds.customer_demographics cd3
    ON sa.ss_cdemo_sk = cd3.cd_demo_sk
JOIN tpcds.household_demographics hd3
    ON sa.ss_hdemo_sk = hd3.hd_demo_sk
JOIN tpcds.customer_demographics cd4
    ON c.c_current_cdemo_sk = cd4.cd_demo_sk
JOIN tpcds.household_demographics hd4
    ON c.c_current_hdemo_sk = hd4.hd_demo_sk
ORDER BY sa.total_sales DESC
LIMIT 100
