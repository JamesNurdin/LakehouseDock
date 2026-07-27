/*
Goal: Identify profit contribution by gender and marital status for customers who have exactly 2 dependents and are single (marital_status = 'S'), ranking each gender by total net profit while also showing subtotals per gender, per marital status and a grand total.
*/
WITH filtered_data AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_ext_wholesale_cost,
        cs.cs_net_profit,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_count = 2
      AND cd.cd_marital_status = 'S'
      AND cs.cs_ext_wholesale_cost > 500
),
agg_data AS (
    SELECT
        fd.cd_gender,
        fd.cd_marital_status,
        fd.cd_dep_count,
        COUNT(DISTINCT fd.cs_order_number) AS distinct_orders,
        SUM(fd.cs_net_profit)            AS total_net_profit,
        SUM(fd.ss_ext_sales_price)       AS total_store_sales,
        GROUPING(fd.cd_gender)           AS g_gender,
        GROUPING(fd.cd_marital_status)   AS g_marital
    FROM filtered_data fd
    WHERE fd.cs_net_profit > (
        SELECT AVG(cs_net_profit)
        FROM catalog_sales
        WHERE cs_ext_wholesale_cost > 500
    )
    GROUP BY ROLLUP (fd.cd_gender, fd.cd_marital_status, fd.cd_dep_count)
)
SELECT
    a.cd_gender,
    a.cd_marital_status,
    a.cd_dep_count,
    a.distinct_orders,
    a.total_net_profit,
    a.total_store_sales,
    RANK() OVER (PARTITION BY a.cd_gender ORDER BY a.total_net_profit DESC) AS gender_profit_rank,
    CASE
        WHEN a.g_gender = 1 AND a.g_marital = 0 THEN 'Subtotal by Gender'
        WHEN a.g_gender = 0 AND a.g_marital = 1 THEN 'Subtotal by Marital'
        WHEN a.g_gender = 1 AND a.g_marital = 1 THEN 'Grand Total'
        ELSE 'Detail'
    END AS row_type
FROM agg_data a
ORDER BY
    a.cd_gender NULLS LAST,
    a.cd_marital_status NULLS LAST,
    a.cd_dep_count
