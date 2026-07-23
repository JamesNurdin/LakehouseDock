WITH sales_return_agg AS (
    SELECT
        w_sales.w_warehouse_id AS w_warehouse_id,
        w_sales.w_warehouse_name AS w_warehouse_name,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN warehouse w_sales
        ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
    JOIN warehouse w_return
        ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE i.i_color = 'red'
      AND p.p_channel_dmail = 'Y'
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY w_sales.w_warehouse_id, w_sales.w_warehouse_name, i.i_item_id, i.i_product_name
)
SELECT
    wa.w_warehouse_id,
    wa.w_warehouse_name,
    SUM(wa.total_sales_profit) - SUM(wa.total_return_loss) AS net_contribution,
    AVG(wa.total_sales_profit - wa.total_return_loss) AS avg_item_net_contribution,
    COUNT(DISTINCT wa.i_item_id) AS distinct_items,
    SUM(wa.total_sales_quantity) AS total_sales_qty,
    SUM(wa.total_return_quantity) AS total_return_qty
FROM sales_return_agg wa
GROUP BY wa.w_warehouse_id, wa.w_warehouse_name
HAVING SUM(wa.total_sales_profit) - SUM(wa.total_return_loss) > 0
ORDER BY net_contribution DESC
LIMIT 100
