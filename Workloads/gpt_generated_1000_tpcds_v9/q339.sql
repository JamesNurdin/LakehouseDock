WITH joined_data AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_ship_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_ship_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_ship_cdemo_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_ext_discount_amt,
    cs.cs_coupon_amt,
    d_sold.d_year,
    d_sold.d_month_seq,
    t.t_am_pm,
    t.t_sub_shift,
    sm.sm_ship_mode_id,
    sm.sm_type,
    p.p_promo_name,
    p.p_discount_active,
    cp.cp_department,
    cust_bill.c_customer_sk AS bill_customer_sk,
    cust_ship.c_customer_sk AS ship_customer_sk,
    cd_bill.cd_gender AS bill_customer_gender,
    cd_shipping.cd_gender AS ship_customer_gender,
    s.s_store_id,
    s.s_store_name,
    d_ship.d_date_sk AS ship_date_sk
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
  JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_shipping
    ON cs.cs_ship_cdemo_sk = cd_shipping.cd_demo_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
  WHERE
    d_sold.d_year = 2001
    AND t.t_am_pm = 'PM'
    AND sm.sm_ship_mode_id = 'AAAAAAAANAAAAAAA'
    AND cs.cs_coupon_amt > 500.00
),
order_intersect AS (
  SELECT cs1.cs_order_number
  FROM catalog_sales cs1
  JOIN promotion p1 ON cs1.cs_promo_sk = p1.p_promo_sk
  WHERE p1.p_channel_tv = 'Y'
  INTERSECT
  SELECT cs2.cs_order_number
  FROM catalog_sales cs2
  JOIN ship_mode sm1 ON cs2.cs_ship_mode_sk = sm1.sm_ship_mode_sk
  WHERE sm1.sm_type = 'Express'
),
filtered_data AS (
  SELECT *
  FROM joined_data jd
  WHERE NOT EXISTS (
      SELECT 1
      FROM catalog_sales cs3
      WHERE cs3.cs_bill_customer_sk = jd.bill_customer_sk
        AND cs3.cs_ext_discount_amt > 1000.00
    )
    AND jd.cs_order_number IN (SELECT cs_order_number FROM order_intersect)
),
agg_data AS (
  SELECT
    fd.d_year,
    fd.d_month_seq,
    fd.cp_department,
    fd.sm_type,
    fd.p_promo_name,
    COUNT(DISTINCT fd.cs_order_number) AS orders_cnt,
    SUM(fd.cs_quantity) AS total_quantity,
    SUM(fd.cs_net_paid) AS total_net_paid,
    AVG(fd.cs_ext_discount_amt) AS avg_discount,
    MIN(fd.cs_coupon_amt) AS min_coupon,
    MAX(fd.cs_coupon_amt) AS max_coupon
  FROM filtered_data fd
  GROUP BY
    fd.d_year,
    fd.d_month_seq,
    fd.cp_department,
    fd.sm_type,
    fd.p_promo_name
)
SELECT
  a.d_year,
  a.d_month_seq,
  a.cp_department,
  a.sm_type,
  a.p_promo_name,
  a.orders_cnt,
  a.total_quantity,
  a.total_net_paid,
  a.avg_discount,
  a.min_coupon,
  a.max_coupon,
  SUM(a.total_net_paid) OVER (PARTITION BY a.d_year ORDER BY a.d_month_seq) AS cumulative_net_paid_year,
  RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_paid DESC) AS rank_by_net_paid
FROM agg_data a
ORDER BY a.d_year, a.d_month_seq DESC, a.total_net_paid DESC
LIMIT 100
