/* goal: Analyze catalog sales performance by order, joining all TPC‑DS dimensions, including dual roles for customers, and comparing to store‑sales for the same item and time. */
WITH avg_price AS (
    SELECT avg(i2.i_current_price) AS avg_item_price
    FROM item i2
)
SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cc.cc_name                         AS call_center_name,
    cp.cp_catalog_page_number,
    sm.sm_type                         AS ship_mode_type,
    w.w_warehouse_name,
    c_bill.c_customer_id               AS bill_customer_id,
    c_bill.c_email_address            AS bill_email,
    c_ship.c_customer_id               AS ship_customer_id,
    cd_bill.cd_gender                  AS bill_gender,
    hd_bill.hd_income_band_sk          AS bill_income_band_sk,
    ib.ib_upper_bound                  AS bill_income_upper_bound,
    ca_bill.ca_city                    AS bill_city,
    r.r_reason_desc                    AS return_reason,
    ss_total.store_sales_total,
    avg_price.avg_item_price,
    item_sales.total_item_sales
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship
  ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss
  ON ss.ss_sold_time_sk = t.t_time_sk
 AND ss.ss_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT sum(cs2.cs_ext_sales_price) AS total_item_sales
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = i.i_item_sk
) AS item_sales
CROSS JOIN LATERAL (
    SELECT sum(ss2.ss_ext_sales_price) AS store_sales_total
    FROM store_sales ss2
    WHERE ss2.ss_sold_time_sk = t.t_time_sk
      AND ss2.ss_item_sk = i.i_item_sk
) AS ss_total
CROSS JOIN avg_price
WHERE cs.cs_sold_date_sk BETWEEN 2450545 AND 2450575
GROUP BY
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cc.cc_name,
    cp.cp_catalog_page_number,
    sm.sm_type,
    w.w_warehouse_name,
    c_bill.c_customer_id,
    c_bill.c_email_address,
    c_ship.c_customer_id,
    cd_bill.cd_gender,
    hd_bill.hd_income_band_sk,
    ib.ib_upper_bound,
    ca_bill.ca_city,
    r.r_reason_desc,
    ss_total.store_sales_total,
    avg_price.avg_item_price,
    item_sales.total_item_sales
ORDER BY cs.cs_net_profit DESC
LIMIT 100
