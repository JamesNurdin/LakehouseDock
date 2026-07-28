WITH sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_catalog_page_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
)
SELECT
    CASE WHEN GROUPING(i.i_item_id) = 0 THEN i.i_item_id ELSE 'ALL_ITEMS' END AS item_id,
    CASE WHEN GROUPING(cc.cc_name) = 0 THEN cc.cc_name ELSE 'ALL_CALL_CENTERS' END AS call_center_name,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(s.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(s.cs_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(s.cs_net_profit) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_bucket,
    COUNT(DISTINCT i.i_category) AS distinct_categories,
    MIN(d_sold.d_date) AS min_sold_date,
    MAX(d_ship.d_date) AS max_ship_date
FROM sales s
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
) wr
    ON s.cs_item_sk = wr.wr_item_sk
    AND s.cs_sold_date_sk = wr.wr_returned_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
GROUP BY GROUPING SETS (
    (i.i_item_id, cc.cc_name),
    (i.i_item_id),
    (cc.cc_name),
    ()
)
ORDER BY total_net_profit DESC
LIMIT 100
