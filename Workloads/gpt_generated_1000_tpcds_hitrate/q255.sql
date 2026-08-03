WITH filtered_dates AS (
    SELECT d_date_sk,
           d_date
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1220
),
inventory_filtered AS (
    SELECT inv_date_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
)
SELECT
    c.c_customer_id,
    fd.d_date,
    cp.cp_catalog_number,
    sm.sm_carrier,
    wh.w_warehouse_name,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Normal' END AS profit_category,
    (
        SELECT COALESCE(SUM(cr.cr_return_amount), 0)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
    ) AS total_return_amount,
    RANK() OVER (PARTITION BY fd.d_date ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    SUM(cs.cs_net_paid) OVER (PARTITION BY c.c_customer_sk ORDER BY fd.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
    ss.ss_quantity AS store_quantity,
    sr.sr_return_quantity,
    r.r_reason_desc
FROM catalog_sales cs
JOIN filtered_dates fd ON cs.cs_sold_date_sk = fd.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
LEFT JOIN inventory_filtered inv ON inv.inv_date_sk = fd.d_date_sk AND inv.inv_warehouse_sk = wh.w_warehouse_sk
LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = fd.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
WHERE
    sm.sm_carrier = 'USPS'
    AND c.c_preferred_cust_flag = 'Y'
    AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%damaged%')
    AND cs.cs_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 800)
ORDER BY profit_rank ASC, c.c_customer_id ASC
LIMIT 100
