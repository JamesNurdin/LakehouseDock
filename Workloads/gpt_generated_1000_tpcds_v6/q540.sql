WITH cs_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IS NOT NULL
)
SELECT
    d_sold.d_year AS sold_year,
    cc.cc_name AS call_center_name,
    p.p_promo_name,
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count
FROM cs_base cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    WHERE ws.ws_order_number = cs.cs_order_number
      AND d_ws_sold.d_year = d_sold.d_year
)
AND cs.cs_order_number IN (
    SELECT wr.wr_order_number
    FROM web_returns wr
    JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    WHERE d_wr_return.d_year = d_sold.d_year
)
GROUP BY
    d_sold.d_year,
    cc.cc_name,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    cd_bill.cd_gender,
    cd_ship.cd_marital_status,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
ORDER BY total_sales DESC
LIMIT 100
