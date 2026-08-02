WITH joined_all AS (
    SELECT
        d.d_year,
        s.s_state,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        cp.cp_department,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        sm.sm_type,
        r.r_reason_desc,
        ws.web_site_id,
        cc.cc_name
    FROM date_dim d
    INNER JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND sm.sm_type IN ('AIR', 'SEA')
      AND cp.cp_department = 'Sports'
      AND r.r_reason_desc LIKE '%damaged%'
),

distinct_sales AS (
    SELECT DISTINCT
        d_year,
        s_state,
        cp_department,
        cs_net_paid,
        cs_net_profit,
        c_customer_id,
        sm_type,
        r_reason_desc,
        web_site_id,
        cc_name
    FROM joined_all
),

sales_agg AS (
    SELECT
        d_year,
        s_state,
        cp_department,
        CASE WHEN cs_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit
    FROM distinct_sales
    GROUP BY d_year, s_state, cp_department,
             CASE WHEN cs_net_profit > 0 THEN 'Positive' ELSE 'Negative' END
),

agg1 AS (
    SELECT
        d_year,
        profit_flag,
        SUM(total_net_paid) AS sum_net_paid,
        SUM(unique_customers) AS sum_unique_customers
    FROM sales_agg
    GROUP BY d_year, profit_flag
),

agg2 AS (
    SELECT
        d_year,
        profit_flag,
        SUM(total_net_profit) AS sum_net_profit,
        COUNT(*) AS department_count
    FROM sales_agg
    GROUP BY d_year, profit_flag
)
SELECT
    d_year,
    profit_flag,
    sum_net_paid AS metric,
    sum_unique_customers AS metric2
FROM agg1
UNION
SELECT
    d_year,
    profit_flag,
    sum_net_profit AS metric,
    department_count AS metric2
FROM agg2
ORDER BY d_year, profit_flag
LIMIT 100
