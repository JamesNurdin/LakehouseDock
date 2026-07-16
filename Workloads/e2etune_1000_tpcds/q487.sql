WITH sales AS (
    SELECT
        cs.cs_warehouse_sk,
        ds_sold.d_quarter_seq,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN date_dim ds_sold
        ON cs.cs_sold_date_sk = ds_sold.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    WHERE ds_sold.d_year = 2002
      AND c.c_birth_year >= 1970
      AND td_sold.t_shift = 'MORN'
),
returns AS (
    SELECT
        cr.cr_warehouse_sk,
        ds_return.d_quarter_seq,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_item_sk
    FROM catalog_returns cr
    JOIN date_dim ds_return
        ON cr.cr_returned_date_sk = ds_return.d_date_sk
    WHERE ds_return.d_year = 2002
),
inventory_agg AS (
    SELECT
        i.inv_warehouse_sk,
        ds_inv.d_quarter_seq,
        AVG(i.inv_quantity_on_hand) AS avg_inv_qty
    FROM inventory i
    JOIN date_dim ds_inv
        ON i.inv_date_sk = ds_inv.d_date_sk
    WHERE ds_inv.d_year = 2002
    GROUP BY i.inv_warehouse_sk, ds_inv.d_quarter_seq
)
SELECT
    w.w_warehouse_name,
    s.d_quarter_seq AS quarter,
    SUM(s.cs_net_profit) AS total_sales_net_profit,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_return_amount,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_return_amount), 0) AS net_profit_after_returns,
    SUM(s.cs_quantity) AS total_sales_quantity,
    COALESCE(SUM(r.cr_return_quantity), 0) AS total_return_quantity,
    ia.avg_inv_qty AS avg_inventory_on_hand
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
   AND s.cs_warehouse_sk = r.cr_warehouse_sk
JOIN warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg ia
    ON s.cs_warehouse_sk = ia.inv_warehouse_sk
   AND s.d_quarter_seq = ia.d_quarter_seq
WHERE w.w_state = 'CA'
GROUP BY w.w_warehouse_name, s.d_quarter_seq, ia.avg_inv_qty
HAVING SUM(s.cs_net_profit) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
