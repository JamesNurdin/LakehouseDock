WITH diff_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
sample_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    cc.cc_name,
    r.r_reason_desc,
    COUNT(DISTINCT c_refund.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT i.i_item_id)      AS distinct_items,
    SUM(ws.ws_net_paid)              AS total_net_paid,
    l.item_sales_sum
FROM
    catalog_returns cr
    JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON cr.cr_returned_time_sk = t1.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    -- Join web_sales and its related dimensions
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    -- Join web_returns and its related dimensions
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
    JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
    -- Join sampled inventory
    JOIN sample_inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d4 ON inv.inv_date_sk = d4.d_date_sk
    -- LATERAL subquery to compute total sales for the item across all web_sales
    CROSS JOIN LATERAL (
        SELECT SUM(ws2.ws_ext_sales_price) AS item_sales_sum
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
    ) l
WHERE
    EXISTS (
        SELECT 1
        FROM web_returns wr3
        WHERE wr3.wr_order_number = cr.cr_order_number
    )
    AND cr.cr_order_number IN (SELECT cr_order_number FROM diff_orders)
GROUP BY
    cc.cc_name,
    r.r_reason_desc,
    l.item_sales_sum
ORDER BY
    total_net_paid DESC
LIMIT 100
