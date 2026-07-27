WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cs.cs_sales_price > 100.00
)
SELECT
    cp.cp_department,
    i.i_category,
    w.w_warehouse_name,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number)                         AS num_orders,
    SUM(cs.cs_ext_sales_price)                                 AS total_sales,
    SUM(cs.cs_net_profit)                                      AS total_profit,
    AVG(cs.cs_coupon_amt)                                      AS avg_coupon,
    SUM(cr.cr_return_amount)                                   AS total_return_amount,
    SUM(sr.sr_return_amt)                                      AS total_store_return_amt,
    COUNT(DISTINCT c.c_customer_id)                            AS unique_customers
FROM base_sales cs
JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr        ON sr.sr_item_sk = i.i_item_sk
JOIN web_page wp              ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'United States'
  AND inv.inv_quantity_on_hand > 0
  AND cp.cp_catalog_page_number BETWEEN 10 AND 20
GROUP BY
    cp.cp_department,
    i.i_category,
    w.w_warehouse_name,
    sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
