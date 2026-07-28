WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 0
)
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    cc.cc_name,
    cp.cp_department,
    buyer.c_first_name || ' ' || buyer.c_last_name AS buyer_name,
    shipper.c_first_name || ' ' || shipper.c_last_name AS shipper_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    wh.w_warehouse_name,
    p.p_promo_name,
    SUM(sales.cs_ext_sales_price) AS total_sales,
    SUM(sales.cs_net_profit) AS total_profit,
    COUNT(DISTINCT sales.cs_order_number) AS orders_count,
    COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM sales
JOIN date_dim d_sales
    ON sales.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON sales.cs_sold_time_sk = t_sales.t_time_sk
JOIN call_center cc
    ON sales.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON sales.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON sales.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh
    ON sales.cs_warehouse_sk = wh.w_warehouse_sk
JOIN promotion p
    ON sales.cs_promo_sk = p.p_promo_sk
JOIN customer buyer
    ON sales.cs_bill_customer_sk = buyer.c_customer_sk
JOIN customer shipper
    ON sales.cs_ship_customer_sk = shipper.c_customer_sk
JOIN household_demographics hd_bill
    ON sales.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON sales.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = buyer.c_customer_sk
    AND sr.sr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    cc.cc_name,
    cp.cp_department,
    buyer.c_first_name,
    buyer.c_last_name,
    shipper.c_first_name,
    shipper.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    wh.w_warehouse_name,
    p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
