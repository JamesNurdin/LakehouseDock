WITH sales_with_dims AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_type,
        sm.sm_carrier,
        td.t_meal_time,
        td.t_sub_shift
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cp.cp_department = 'Books'
      AND sm.sm_carrier = 'UPS'
      AND td.t_meal_time = 'dinner'
      AND td.t_sub_shift = 'evening'
)
SELECT
    swd.cp_department,
    swd.sm_carrier,
    swd.t_meal_time,
    COUNT(*) AS sales_cnt,
    SUM(swd.cs_quantity) AS total_quantity,
    SUM(swd.cs_ext_sales_price) AS total_sales,
    AVG(swd.cs_net_profit) AS avg_profit,
    MIN(swd.cs_ext_sales_price) AS min_sale,
    MAX(swd.cs_ext_sales_price) AS max_sale
FROM sales_with_dims swd
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = swd.cs_order_number
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 100
)
GROUP BY swd.cp_department, swd.sm_carrier, swd.t_meal_time
HAVING SUM(swd.cs_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
