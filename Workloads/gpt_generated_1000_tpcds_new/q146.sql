/*
Goal: Summarize net profit, return loss and sales quantity per catalog department and promotion for sales in the year 2001, excluding orders that were fully returned. The query demonstrates deep joins across all ten selected tables, re‑uses the DATE_DIM and CUSTOMER_DEMOGRAPHICS tables under multiple aliases, subtracts returned orders using EXCEPT, and compares sales quantity against an uncorrelated scalar subquery that returns the maximum inventory quantity.
*/
WITH sales_2001 AS (
    SELECT cs.*
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns_2001 AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
order_set AS (
    SELECT cs_order_number FROM sales_2001
    EXCEPT
    SELECT cr_order_number FROM returns_2001
)
SELECT
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type,
    d_sold.d_month_seq,
    COUNT(DISTINCT s.cs_order_number)            AS num_orders,
    SUM(s.cs_net_profit)                         AS total_profit,
    SUM(COALESCE(cr.cr_return_amount, 0))        AS total_return_amount,
    SUM(s.cs_quantity)                           AS total_quantity,
    SUM(CASE WHEN s.cs_quantity > (SELECT MAX(inv_quantity_on_hand) FROM inventory) THEN s.cs_quantity ELSE 0 END) AS quantity_exceeding_max_inventory
FROM sales_2001 s
JOIN order_set os
    ON s.cs_order_number = os.cs_order_number
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON s.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON s.cs_order_number = cr.cr_order_number
   AND cr.cr_item_sk = s.cs_item_sk
LEFT JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = s.cs_sold_date_sk
   AND inv.inv_item_sk = s.cs_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_ws_open
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
GROUP BY
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type,
    d_sold.d_month_seq
ORDER BY total_profit DESC
LIMIT 100
