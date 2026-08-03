WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_quantity,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        p.p_promo_id,
        ca.ca_state,
        td.t_hour,
        inv.inv_quantity_on_hand,
        (cr.cr_net_loss + sr.sr_net_loss) AS total_loss,
        CASE WHEN ws.ws_net_profit > 100 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM
        time_dim td
        JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND i.i_current_price > 20
        AND inv.inv_quantity_on_hand > 0
        AND p.p_channel_dmail = 'Y'
        AND ca.ca_state IN ('CA', 'NY', 'TX')
        AND ws.ws_net_profit > 0
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
              AND p2.p_channel_email = 'Y'
        )
)
SELECT
    profit_category,
    i_category,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    SUM(total_loss) AS sum_total_loss,
    AVG(ws_net_profit) AS avg_net_profit,
    SUM(CASE WHEN profit_category = 'HIGH' THEN ws_net_profit ELSE 0 END) AS high_profit_sum
FROM
    base
GROUP BY
    profit_category,
    i_category
HAVING
    SUM(total_loss) > 1000
ORDER BY
    sum_total_loss DESC
LIMIT 100
