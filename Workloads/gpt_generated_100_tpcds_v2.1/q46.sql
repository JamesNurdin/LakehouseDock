WITH filtered_sales AS (
    SELECT
        cc.cc_name AS cc_name,
        cc.cc_state AS cc_state,
        sm.sm_carrier AS sm_carrier,
        sm.sm_code AS sm_code,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_ext_tax AS ext_tax,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_city = 'Lakeview 10th'
      AND cc.cc_street_type = 'Drive'
      AND cc.cc_gmt_offset BETWEEN -5.00 AND -4.00
      AND cc.cc_rec_start_date >= DATE '2020-01-01'
      AND cc.cc_rec_start_date < DATE '2021-01-01'
      AND cs.cs_ext_tax > 100.00
      AND cs.cs_coupon_amt > 0.00
      AND sm.sm_carrier = 'FEDEX'
      AND sm.sm_code = 'AIR'
)
SELECT
    cc_name,
    cc_state,
    sm_carrier,
    sm_code,
    COUNT(DISTINCT order_number) AS order_cnt,
    SUM(quantity) AS total_quantity,
    SUM(ext_sales_price) AS total_sales,
    AVG(ext_discount_amt) AS avg_discount,
    MIN(ext_tax) AS min_tax,
    MAX(ext_tax) AS max_tax,
    SUM(net_profit) AS total_net_profit
FROM filtered_sales
GROUP BY cc_name, cc_state, sm_carrier, sm_code
ORDER BY total_sales DESC
LIMIT 100
