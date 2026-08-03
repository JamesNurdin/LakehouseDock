WITH sampled_sales AS (
  SELECT *
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
),
joined AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_ship_customer_sk,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_promo_sk,
    cs.cs_item_sk,
    d_sold.d_date               AS sold_date,
    t_sold.t_hour               AS sold_hour,
    cust_bill.c_first_name      AS bill_first_name,
    cust_bill.c_last_name       AS bill_last_name,
    cust_ship.c_first_name      AS ship_first_name,
    cust_ship.c_last_name       AS ship_last_name,
    cc.cc_name                  AS call_center_name,
    sm.sm_type                  AS ship_type,
    w.w_warehouse_name,
    p.p_promo_name,
    ds_start.d_date             AS promo_start_date,
    ds_end.d_date               AS promo_end_date,
    cr.cr_return_amount,
    wr.wr_fee,
    ws.web_name
  FROM sampled_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim ds_start
    ON p.p_start_date_sk = ds_start.d_date_sk
  JOIN date_dim ds_end
    ON p.p_end_date_sk = ds_end.d_date_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  LEFT JOIN web_returns wr
    ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
   AND cr.cr_returned_time_sk = wr.wr_returned_time_sk
   AND cr.cr_refunded_customer_sk = wr.wr_refunded_customer_sk
  LEFT JOIN web_site ws
    ON ws.web_open_date_sk = cs.cs_sold_date_sk
)
SELECT
  j.*, 
  (j.cs_quantity * j.cs_net_paid)                      AS revenue_estimate,
  ROW_NUMBER() OVER (ORDER BY j.cs_net_paid DESC)    AS row_num,
  lt.lateral_revenue
FROM joined j
CROSS JOIN LATERAL (
  SELECT (j.cs_quantity * j.cs_net_paid) AS lateral_revenue
) lt
ORDER BY row_num
OFFSET 0
LIMIT 100
