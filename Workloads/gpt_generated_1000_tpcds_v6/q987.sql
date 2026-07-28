WITH cs AS (
    SELECT
        cs_order_number,
        cs_sold_time_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_quantity,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        cs_net_profit
    FROM catalog_sales
    WHERE cs_quantity > 5
      AND cs_ext_sales_price > 1000
),
wr AS (
    SELECT
        wr_order_number,
        wr_returned_time_sk,
        wr_return_amt_inc_tax,
        wr_reversed_charge
    FROM web_returns
    WHERE wr_reversed_charge > 100
      AND wr_return_amt_inc_tax > 200
)
SELECT
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    td.t_hour,
    COUNT(DISTINCT cs.cs_order_number) AS orders_sold,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT wr.wr_order_number) AS returns_count,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
FROM cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN wr ON wr.wr_returned_time_sk = td.t_time_sk
WHERE cc.cc_company_name IN ('anti', 'ese')
  AND cc.cc_company = 2
  AND sm.sm_contract = 'OrDuVy2H'
  AND w.w_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    td.t_hour
ORDER BY total_profit DESC
LIMIT 100
