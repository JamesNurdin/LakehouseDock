WITH sales_with_date AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
)
SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month,
    cc.cc_state AS state,
    sm.sm_type AS ship_type,
    SUM(s.cs_ext_sales_price) AS total_sales,
    SUM(s.cs_net_profit) AS total_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(s.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit_after_returns,
    AVG(s.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT s.cs_order_number) AS order_count
FROM sales_with_date s
JOIN date_dim d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_returns cr
    ON s.cs_order_number = cr.cr_order_number
    AND s.cs_item_sk = cr.cr_item_sk
WHERE d_sold.d_year = 2002
GROUP BY d_sold.d_year, d_sold.d_month_seq, cc.cc_state, sm.sm_type
ORDER BY d_sold.d_year, d_sold.d_month_seq, cc.cc_state, sm.sm_type
