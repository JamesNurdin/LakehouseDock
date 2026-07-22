SELECT
    d1.d_year,
    d1.d_month_seq,
    hd1.hd_buy_potential,
    wp.wp_type,
    COUNT(DISTINCT c1.c_customer_sk) AS distinct_customers,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    AVG(cs.cs_net_profit) AS avg_sales_net_profit,
    MIN(i.inv_quantity_on_hand) AS min_inventory_on_hand,
    MAX(i.inv_quantity_on_hand) AS max_inventory_on_hand
FROM store_returns sr
JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
JOIN time_dim t1 ON sr.sr_return_time_sk = t1.t_time_sk
JOIN customer c1 ON sr.sr_customer_sk = c1.c_customer_sk
JOIN household_demographics hd1 ON sr.sr_hdemo_sk = hd1.hd_demo_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d1.d_date_sk
    AND cs.cs_sold_time_sk = t1.t_time_sk
    AND cs.cs_bill_customer_sk = c1.c_customer_sk
    AND cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_returned_date_sk = d1.d_date_sk
    AND cr.cr_returned_time_sk = t1.t_time_sk
    AND cr.cr_refunded_customer_sk = c1.c_customer_sk
    AND cr.cr_refunded_hdemo_sk = hd1.hd_demo_sk
JOIN inventory i ON i.inv_date_sk = d1.d_date_sk
JOIN web_page wp ON wp.wp_customer_sk = c1.c_customer_sk
    AND wp.wp_creation_date_sk = d1.d_date_sk
WHERE d1.d_year = 2000
  AND t1.t_hour = 13
  AND c1.c_birth_day = 25
  AND sr.sr_return_tax > 10.00
  AND hd1.hd_vehicle_count >= 2
  AND wp.wp_autogen_flag = 'N'
GROUP BY d1.d_year, d1.d_month_seq, hd1.hd_buy_potential, wp.wp_type
ORDER BY total_sales_net_paid DESC, d1.d_year DESC
LIMIT 100
