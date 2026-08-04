WITH
catalog_fact AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    d.d_year,
    i.i_item_id,
    p.p_promo_id,
    sm.sm_carrier,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    SUM(cs.cs_net_paid) AS total_paid,
    COUNT(*) AS cnt_sales
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND sm.sm_carrier = 'MSC'
    AND ib.ib_lower_bound >= 50000
    AND i.i_container = 'Unknown'
  GROUP BY cs.cs_order_number, cs.cs_sold_date_sk, d.d_year, i.i_item_id,
           p.p_promo_id, sm.sm_carrier, c.c_customer_id, cd.cd_gender,
           hd.hd_income_band_sk, ib.ib_lower_bound
  HAVING SUM(cs.cs_net_paid) > 1000
),
web_ret_fact AS (
  SELECT
    wr.wr_order_number,
    d2.d_year,
    i2.i_item_id,
    wp.wp_type,
    c2.c_customer_id,
    cd2.cd_gender,
    hd2.hd_income_band_sk,
    ib2.ib_lower_bound,
    SUM(wr.wr_return_amt) AS total_return,
    COUNT(*) AS cnt_returns
  FROM web_returns wr
  JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
  JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
  JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN customer c2 ON wr.wr_refunded_customer_sk = c2.c_customer_sk
  JOIN customer_demographics cd2 ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
  JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
  JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
  WHERE d2.d_year BETWEEN 2000 AND 2002
    AND wp.wp_type = 'Content'
    AND ib2.ib_upper_bound <= 120000
    AND i2.i_color = 'Red'
  GROUP BY wr.wr_order_number, d2.d_year, i2.i_item_id,
           wp.wp_type, c2.c_customer_id, cd2.cd_gender,
           hd2.hd_income_band_sk, ib2.ib_lower_bound
  HAVING SUM(wr.wr_return_amt) > 500
),
intersect_orders AS (
  SELECT cs_order_number AS order_id FROM catalog_fact
  INTERSECT
  SELECT wr_order_number FROM web_ret_fact
),
full_outer_sales_returns AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    cr.cr_returned_date_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount
  FROM store_sales ss
  FULL OUTER JOIN catalog_returns cr
    ON ss.ss_sold_date_sk = cr.cr_returned_date_sk
  WHERE ss.ss_sold_date_sk IS NOT NULL OR cr.cr_returned_date_sk IS NOT NULL
),
ranked_result AS (
  SELECT
    cf.d_year,
    cf.i_item_id,
    cf.total_paid,
    cf.cnt_sales,
    ROW_NUMBER() OVER (PARTITION BY cf.d_year ORDER BY cf.total_paid DESC) AS rn
  FROM catalog_fact cf
  WHERE cf.cs_order_number IN (SELECT order_id FROM intersect_orders)
)
SELECT
  r.d_year,
  r.i_item_id,
  r.total_paid,
  r.cnt_sales,
  r.rn
FROM ranked_result r
WHERE r.rn <= 5
ORDER BY r.d_year DESC, r.total_paid DESC
LIMIT 100
