WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE c.c_birth_year BETWEEN 1935 AND 1970
      AND cd.cd_purchase_estimate >= 2000
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_login IS NOT NULL
      AND ss.ss_quantity > 0
      AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_customer_sk = c.c_customer_sk
              AND wp.wp_autogen_flag = 'N'
              AND wp.wp_rec_start_date >= DATE '1999-01-01'
        )
    GROUP BY
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        t.t_hour
)
SELECT
    COALESCE(c_customer_id, 'ALL') AS customer_id,
    cd_gender,
    cd_marital_status,
    t_hour,
    SUM(total_sales) AS sum_sales,
    AVG(total_profit) AS avg_profit,
    SUM(txn_count) AS total_txn,
    GROUPING(c_customer_id) AS grp_customer,
    GROUPING(cd_gender) AS grp_gender,
    GROUPING(cd_marital_status) AS grp_marital,
    GROUPING(t_hour) AS grp_hour
FROM sales_agg
GROUP BY ROLLUP (c_customer_id, cd_gender, cd_marital_status, t_hour)
ORDER BY
    grp_customer,
    customer_id,
    cd_gender,
    cd_marital_status,
    t_hour
LIMIT 100
