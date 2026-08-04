WITH cs_agg AS (
    SELECT
        cs_order_number,
        cs_bill_customer_sk,
        cs_ship_customer_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_sold_time_sk,
        SUM(cs_net_paid)        AS total_net_paid,
        SUM(cs_net_profit)      AS total_net_profit,
        COUNT(*)                AS sales_cnt
    FROM catalog_sales
    GROUP BY cs_order_number, cs_bill_customer_sk, cs_ship_customer_sk,
             cs_call_center_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_sold_time_sk
),
cs_orders AS (
    SELECT cs_order_number FROM cs_agg
),
wr_orders AS (
    SELECT wr_order_number FROM web_returns
),
non_returned_sales AS (
    SELECT cs_order_number FROM cs_orders
    EXCEPT
    SELECT wr_order_number FROM wr_orders
),
sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_return_time_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss)  AS total_net_loss,
        COUNT(*)          AS return_cnt
    FROM store_returns
    GROUP BY sr_customer_sk, sr_return_time_sk
)
SELECT
    c_bill.c_first_name || ' ' || c_bill.c_last_name         AS bill_customer_name,
    c_ship.c_first_name || ' ' || c_ship.c_last_name         AS ship_customer_name,
    cc.cc_name                                               AS call_center_name,
    sm.sm_type                                               AS ship_mode_type,
    w.w_warehouse_name                                       AS warehouse_name,
    t_sold.t_hour                                            AS sold_hour,
    ns.cs_order_number,
    ns.total_net_paid,
    ns.total_net_profit,
    CASE WHEN ns.total_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    COALESCE(sr.total_return_amt, 0)                         AS total_return_amount,
    COALESCE(sr.total_net_loss, 0)                           AS total_return_loss
FROM non_returned_sales nrs
JOIN cs_agg ns
    ON ns.cs_order_number = nrs.cs_order_number
JOIN customer c_bill
    ON ns.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON ns.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN call_center cc
    ON ns.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON ns.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ns.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_sold
    ON ns.cs_sold_time_sk = t_sold.t_time_sk
LEFT JOIN sr_agg sr
    ON sr.sr_customer_sk = c_bill.c_customer_sk
LEFT JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
WHERE t_sold.t_am_pm = 'PM'
ORDER BY ns.total_net_paid DESC
LIMIT 100
