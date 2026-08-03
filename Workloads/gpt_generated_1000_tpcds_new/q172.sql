/*
  Goal: Analyze net profit and return amount by call center, item manufacturer and brand for the year 2001, 
  showing sales performance together with return information. The query joins all twelve selected TPC‑DS tables, 
  re‑uses the DATE_DIM table under several aliases, uses a FULL OUTER JOIN between CATALOG_SALES and CATALOG_RETURNS
  to retain rows that have only sales or only returns, and adds a correlated scalar sub‑query that reports the 
  total return amount for each item.
*/
SELECT
  cc.cc_name,
  i.i_manufact_id,
  i.i_brand,
  d_sold.d_year,
  SUM(COALESCE(cs.cs_net_profit, 0))                         AS total_net_profit,
  SUM(COALESCE(cr.cr_return_amount, 0))                     AS total_return_amount,
  COUNT(DISTINCT cs.cs_order_number)                        AS sales_orders,
  COUNT(DISTINCT cr.cr_order_number)                        AS return_orders,
  (SELECT SUM(cr2.cr_return_amount)
     FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = i.i_item_sk)                    AS total_return_amount_for_item
FROM catalog_sales cs
FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
-- join dimensions for the sales side
JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
-- join dimensions for the return side
LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
-- additional date joins for call‑center life‑cycle
LEFT JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
LEFT JOIN date_dim d_cc_close
        ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
-- web related tables (joined via customer and date keys)
LEFT JOIN web_page wp
        ON wp.wp_customer_sk = cust_bill.c_customer_sk
LEFT JOIN date_dim d_wp_create
        ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
LEFT JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
  cc.cc_name,
  i.i_manufact_id,
  i.i_brand,
  d_sold.d_year,
  i.i_item_sk
ORDER BY total_net_profit DESC
LIMIT 100
