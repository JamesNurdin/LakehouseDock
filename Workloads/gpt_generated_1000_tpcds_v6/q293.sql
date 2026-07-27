SELECT
    s.s_store_name,
    i.i_category,
    d_date.d_year,
    p.p_promo_name,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
FROM
    store_sales ss
JOIN date_dim d_date
    ON ss.ss_sold_date_sk = d_date.d_date_sk
JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_cust
    ON ss.ss_cdemo_sk = cd_cust.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_date.d_date_sk
   AND cs.cs_item_sk = i.i_item_sk
   AND cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_ship_date
    ON cs.cs_ship_date_sk = d_ship_date.d_date_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = ss.ss_item_sk
      AND cs2.cs_sold_date_sk = ss.ss_sold_date_sk
      AND cs2.cs_ext_sales_price > 1000
)
GROUP BY
    s.s_store_name,
    i.i_category,
    d_date.d_year,
    p.p_promo_name
ORDER BY
    store_sales_amount DESC
LIMIT 100
