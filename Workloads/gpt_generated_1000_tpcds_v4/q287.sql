WITH ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_promo_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        SUM(ws_net_paid)      AS total_net_paid,
        SUM(ws_quantity)      AS total_qty
    FROM tpcds.web_sales
    GROUP BY
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_promo_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk
)
SELECT
    c_bill.c_first_name,
    c_bill.c_last_name,
    s.s_store_name,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    d_sold.d_year,
    ws_agg.total_qty,
    ws_agg.total_net_paid,
    CASE WHEN ws_agg.total_net_paid > 5000 THEN 'High' ELSE 'Low' END AS sales_category
FROM ws_agg
-- Customer dimensions (billing and shipping)
JOIN tpcds.customer c_bill ON ws_agg.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.customer c_ship ON ws_agg.ws_ship_customer_sk = c_ship.c_customer_sk
-- Ship mode, warehouse, promotion
JOIN tpcds.ship_mode sm          ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w           ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p           ON ws_agg.ws_promo_sk = p.p_promo_sk
-- Date dimensions for sold, ship, customer first ship, promotion start/end
JOIN tpcds.date_dim d_sold            ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship            ON ws_agg.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.date_dim d_cust_first_ship ON c_bill.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN tpcds.date_dim d_promo_start     ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN tpcds.date_dim d_promo_end       ON p.p_end_date_sk = d_promo_end.d_date_sk
-- Store linked through its closed‑date surrogate key
JOIN tpcds.date_dim d_store_closed ON TRUE
JOIN tpcds.store s ON s.s_closed_date_sk = d_store_closed.d_date_sk
ORDER BY ws_agg.total_net_paid DESC
LIMIT 100
