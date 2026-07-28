WITH base AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        p.p_promo_id,
        ss.ss_ticket_number,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        p.p_discount_active,
        wr.wr_net_loss AS wr_net_loss,
        wr.wr_fee,
        i.inv_quantity_on_hand,
        ws.ws_sold_date_sk,
        ws.ws_quantity
    FROM store_sales ss
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT OUTER JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = ws.ws_sold_date_sk
    WHERE
        cr.cr_return_quantity > 1
        AND cr.cr_return_amount >= 50.00
        AND p.p_discount_active = 'Y'
        AND w.w_state = 'CA'
        AND i.inv_quantity_on_hand < 500
        AND wr.wr_fee > 20.00
        AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451925
) 
SELECT
    w_warehouse_id,
    w_city,
    p_promo_id,
    COUNT(DISTINCT ss_ticket_number) AS store_sales_cnt,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(cr_net_loss) AS total_catalog_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand
FROM base
GROUP BY
    w_warehouse_id,
    w_city,
    p_promo_id
HAVING
    (SUM(cr_net_loss) + SUM(wr_net_loss)) > 1000
