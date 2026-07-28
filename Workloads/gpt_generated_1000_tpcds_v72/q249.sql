WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_warehouse_sk,
        cs_catalog_page_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM catalog_sales
    WHERE cs_quantity >= 2
      AND cs_wholesale_cost BETWEEN 10 AND 100
      AND cs_ext_discount_amt < 5000
      AND cs_ext_tax > 0
      AND cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs_ship_mode_sk IS NOT NULL
    GROUP BY cs_call_center_sk, cs_warehouse_sk, cs_catalog_page_sk
)
SELECT
    CASE WHEN GROUPING(cc.cc_name) = 0 THEN cc.cc_name ELSE 'ALL_CALL_CENTERS' END AS call_center_name,
    CASE WHEN GROUPING(w.w_warehouse_name) = 0 THEN w.w_warehouse_name ELSE 'ALL_WAREHOUSES' END AS warehouse_name,
    CASE WHEN GROUPING(cp.cp_department) = 0 THEN cp.cp_department ELSE 'ALL_DEPARTMENTS' END AS department,
    SUM(s.total_sales) AS sum_sales,
    SUM(s.total_profit) AS sum_profit,
    SUM(s.order_cnt) AS total_orders,
    CASE
        WHEN SUM(s.total_sales) > 50000 THEN 'BIG'
        WHEN SUM(s.total_sales) > 20000 THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS sales_volume_category
FROM sales_agg s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cc.cc_state = 'CA'
  AND w.w_state = 'CA'
  AND cp.cp_type = 'PROMO'
  AND cc.cc_gmt_offset BETWEEN -5 AND 5
  AND w.w_gmt_offset BETWEEN -5 AND 5
  AND cc.cc_employees > 0
GROUP BY GROUPING SETS (
    (cc.cc_name, w.w_warehouse_name, cp.cp_department),
    (cc.cc_name, w.w_warehouse_name),
    (cc.cc_name, cp.cp_department),
    (w.w_warehouse_name, cp.cp_department),
    (cc.cc_name),
    (w.w_warehouse_name),
    (cp.cp_department),
    ()
)
ORDER BY call_center_name, warehouse_name, department
