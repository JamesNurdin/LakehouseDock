WITH dept_hour_sales AS (
    SELECT
        cp.cp_department,
        td.t_hour,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs.cs_net_profit) > 5000 THEN 'HIGH_PROFIT' ELSE 'LOW_PROFIT' END AS profit_category
    FROM catalog_sales cs
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451200
      AND td.t_am_pm = 'PM'
      AND cs.cs_ext_ship_cost > 100
      AND cs.cs_quantity >= 2
    GROUP BY cp.cp_department, td.t_hour
)
SELECT
    dhs.cp_department,
    dhs.t_hour,
    dhs.total_net_paid,
    dhs.total_profit,
    dhs.avg_profit,
    dhs.order_count,
    dhs.profit_category,
    CASE WHEN dhs.total_profit > (SELECT AVG(cs.cs_net_profit) FROM catalog_sales cs) THEN 'ABOVE_GLOBAL_AVG' ELSE 'BELOW_GLOBAL_AVG' END AS profit_vs_global
FROM dept_hour_sales dhs
WHERE dhs.order_count > 10
ORDER BY dhs.total_net_paid DESC
LIMIT 100
