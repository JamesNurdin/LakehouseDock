WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    cc.cc_name AS call_center_name,
    sm.sm_carrier,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    SUM(inv_agg.total_qty_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_billing_customers,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN call_center cc_ret
    ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
LEFT JOIN ship_mode sm_ret
    ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN inv_agg
    ON cs.cs_item_sk = inv_agg.inv_item_sk
    AND cs.cs_sold_date_sk = inv_agg.inv_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
    AND wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND sm.sm_type = 'REGULAR'
GROUP BY
    cc.cc_name,
    sm.sm_carrier,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
