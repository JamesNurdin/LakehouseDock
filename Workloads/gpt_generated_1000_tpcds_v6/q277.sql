WITH inventory_summary AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    s.s_store_name,
    cc_sales.cc_name        AS sales_call_center,
    p.p_promo_name,
    SUM(cs.cs_net_profit)           AS total_profit,
    SUM(cr.cr_return_amount)        AS total_return_amount,
    SUM(sr.sr_return_amt)           AS total_store_return_amt,
    SUM(wr.wr_return_amt)           AS total_web_return_amt,
    SUM(isum.total_qty)             AS total_inventory_qty
FROM
    catalog_sales cs
    JOIN call_center cc_sales
        ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
    JOIN warehouse w_sales
        ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    /* catalog_returns linked to catalog_sales */
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN call_center cc_ret
        ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    JOIN warehouse w_ret
        ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    JOIN customer_address ca_ret_refund
        ON cr.cr_refunded_addr_sk = ca_ret_refund.ca_address_sk
    JOIN customer_address ca_ret_return
        ON cr.cr_returning_addr_sk = ca_ret_return.ca_address_sk
    /* store and its returns */
    JOIN store s
        ON 1 = 1                     -- cross‑join to bring the store dimension into the query
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca_sr_addr
        ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
    /* web returns linked via the same bill/ship addresses as the sale */
    JOIN web_returns wr
        ON wr.wr_refunded_addr_sk = ca_bill.ca_address_sk
       AND wr.wr_returning_addr_sk = ca_ship.ca_address_sk
    /* inventory summary (pre‑aggregated) */
    JOIN inventory_summary isum
        ON w_sales.w_warehouse_sk = isum.inv_warehouse_sk
WHERE
    EXISTS (
        SELECT 1
        FROM promotion p_sub
        WHERE p_sub.p_promo_sk = cs.cs_promo_sk
          AND p_sub.p_discount_active = 'Y'
    )
GROUP BY
    ROLLUP (s.s_store_name, cc_sales.cc_name, p.p_promo_name)
ORDER BY
    total_profit DESC
LIMIT 100
