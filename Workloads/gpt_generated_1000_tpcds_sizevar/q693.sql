WITH sampled_sales AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
        WHERE cs_coupon_amt > 0
    ),
    filtered_sales AS (
        SELECT *
        FROM sampled_sales
        WHERE cs_sold_time_sk BETWEEN 40000 AND 80000
          AND cs_ship_date_sk > 2450800
          AND cs_quantity >= 1
          AND cs_net_profit > 0
    ),
    included_cc AS (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_state = 'CA'
    ),
    excluded_cc AS (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_gmt_offset < 0
    ),
    target_cc AS (
        SELECT cc_call_center_sk FROM included_cc
        EXCEPT
        SELECT cc_call_center_sk FROM excluded_cc
    ),
    first_part AS (
        SELECT
            cc.cc_name AS entity_name,
            i.i_category AS category,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            AVG(cs.cs_ext_discount_amt) AS avg_discount,
            CASE WHEN SUM(cs.cs_coupon_amt) = 0 THEN 'NoCoupon' ELSE 'HasCoupon' END AS coupon_flag,
            ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank
        FROM filtered_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_call_center_sk IN (SELECT cc_call_center_sk FROM target_cc)
        GROUP BY cc.cc_name, i.i_category
    ),
    second_part AS (
        SELECT
            sm.sm_type AS entity_name,
            cp.cp_department AS category,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            AVG(cs.cs_ext_discount_amt) AS avg_discount,
            CASE WHEN SUM(cs.cs_coupon_amt) = 0 THEN 'NoCoupon' ELSE 'HasCoupon' END AS coupon_flag,
            ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank
        FROM filtered_sales cs
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE sm.sm_carrier IN ('USPS', 'ALLIANCE')
          AND cp.cp_type = 'WEB'
        GROUP BY sm.sm_type, cp.cp_department
    )
SELECT *
FROM (
        SELECT * FROM first_part
        UNION DISTINCT
        SELECT * FROM second_part
) AS combined
ORDER BY total_sales DESC
LIMIT 100
