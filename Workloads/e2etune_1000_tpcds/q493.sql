WITH dept_shift_sales AS (
    SELECT
        cp.cp_department AS department,
        td.t_shift AS shift,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_net_profit) AS avg_profit_per_sale
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_catalog_number IN (1, 2)
      AND cp.cp_end_date_sk > 2450900
      AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2451100
      AND hd.hd_vehicle_count >= 2
    GROUP BY cp.cp_department, td.t_shift
    HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
    department,
    shift,
    total_net_profit,
    total_quantity,
    avg_profit_per_sale,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM dept_shift_sales
ORDER BY total_net_profit DESC
LIMIT 20
