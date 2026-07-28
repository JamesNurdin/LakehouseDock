WITH item_sales AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    GROUP BY cs.cs_item_sk
),
item_inventory AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM tpcds.inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT
    cs.cs_order_number,
    cc.cc_name,
    cp.cp_type,
    w.w_warehouse_name,
    i.i_product_name,
    c_bill.c_first_name || ' ' || c_bill.c_last_name AS bill_customer,
    t1.t_hour,
    ws.ws_net_paid AS web_net_paid,
    sr.sr_return_amt AS store_return_amt,
    cr.cr_return_amount AS catalog_return_amount,
    isales.total_net_paid,
    isales.total_profit,
    iinv.total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_profit DESC) AS profit_rank_by_category,
    (
        SELECT COUNT(*)
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
    ) AS store_return_cnt
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.time_dim t1
    ON cs.cs_sold_time_sk = t1.t_time_sk
JOIN tpcds.web_sales ws
    ON ws.ws_sold_time_sk = t1.t_time_sk
    AND ws.ws_item_sk = i.i_item_sk
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.store_returns sr
    ON sr.sr_return_time_sk = t1.t_time_sk
    AND sr.sr_item_sk = i.i_item_sk
JOIN tpcds.customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_time_sk = t1.t_time_sk
    AND cr.cr_item_sk = i.i_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN tpcds.customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN tpcds.customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN item_sales isales
    ON isales.cs_item_sk = i.i_item_sk
LEFT JOIN item_inventory iinv
    ON iinv.inv_item_sk = i.i_item_sk
WHERE i.i_current_price > 5.00
  AND w.w_state = 'CA'
  AND t1.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
          AND ws2.ws_net_paid > 100
    )
ORDER BY total_profit DESC, profit_rank_by_category
LIMIT 100
