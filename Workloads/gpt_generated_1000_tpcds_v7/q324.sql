/*
  Goal: Rank the highest‑value orders (net paid) within each warehouse for the year 1999,
  applying several business filters across dimensions such as quantity, discount, education,
  shipping mode, call‑center location, and warehouse location.
*/
WITH sales_detail AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        d_sold.d_date      AS sold_date,
        d_sold.d_year,
        c.c_customer_id,
        cd.cd_education_status,
        ca.ca_city,
        cc.cc_name,
        cc.cc_state,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_state
    FROM tpcds.catalog_sales AS cs
    JOIN tpcds.date_dim AS d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.date_dim AS d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.customer AS c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics AS cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address AS ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.call_center AS cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page AS cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode AS sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse AS w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d_sold.d_year = 1999                                 -- filter 1: sold in 1999
      AND cs.cs_quantity > 5                                   -- filter 2: minimum quantity
      AND cs.cs_ext_discount_amt > 100.00                     -- filter 3: substantial discount
      AND cd.cd_education_status = 'College'                  -- filter 4: college‑educated customers
      AND sm.sm_type = 'AIR'                                   -- filter 5: air shipping mode
      AND cc.cc_state = 'CA'                                   -- filter 6: call center in CA
      AND w.w_state = 'CA'                                     -- filter 7: warehouse in CA
)
SELECT
    sd.cs_order_number,
    sd.c_customer_id,
    sd.sold_date,
    sd.cs_net_paid,
    sd.cs_quantity,
    sd.cs_ext_discount_amt,
    sd.cc_name,
    sd.cp_department,
    sd.sm_type,
    sd.w_warehouse_name,
    ROW_NUMBER() OVER (
        PARTITION BY sd.w_warehouse_name
        ORDER BY sd.cs_net_paid DESC
    ) AS warehouse_sales_rank,
    RANK() OVER (
        PARTITION BY sd.w_warehouse_name
        ORDER BY sd.cs_net_paid DESC
    ) AS warehouse_sales_dense_rank
FROM sales_detail AS sd
ORDER BY sd.w_warehouse_name, warehouse_sales_rank
LIMIT 100
