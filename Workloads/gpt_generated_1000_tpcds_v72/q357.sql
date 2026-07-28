WITH sales_base AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 50
)
SELECT
    cc.cc_name,
    sm.sm_code,
    td.t_meal_time,
    i.i_brand,
    CASE WHEN i.i_current_price > 100 THEN 'HIGH' ELSE 'LOW' END AS price_category,
    SUM(sb.cs_ext_sales_price) AS total_sales,
    AVG(sb.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT sb.cs_order_number) AS distinct_orders
FROM sales_base sb
JOIN time_dim td
    ON sb.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc
    ON sb.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON sb.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON sb.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c_bill
    ON sb.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
    ON sb.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
WHERE
    cc.cc_state = 'CA'
    AND sm.sm_code IN ('AIR', 'SEA')
    AND td.t_meal_time = 'dinner'
    AND i.i_brand = 'Brand#12'
    AND i.i_current_price > 100
    AND cp.cp_department = 'DEPARTMENT'
GROUP BY
    cc.cc_name,
    sm.sm_code,
    td.t_meal_time,
    i.i_brand,
    CASE WHEN i.i_current_price > 100 THEN 'HIGH' ELSE 'LOW' END
ORDER BY total_sales DESC
LIMIT 100
