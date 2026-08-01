WITH base AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_brand_id,
        ca_store.ca_state AS store_state,
        ca_refund.ca_state AS refunded_state,
        td_store.t_meal_time,
        td_store.t_hour AS store_hour,
        td_catalog.t_meal_time AS catalog_meal_time,
        td_catalog.t_hour AS catalog_hour,
        cp_lateral.cp_description,
        cp_lateral.cp_catalog_number,
        CASE
            WHEN cr.cr_net_loss > 0 THEN 'Loss'
            WHEN cr.cr_net_loss = 0 THEN 'Break-even'
            ELSE 'Gain'
        END AS loss_category
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca_store
        ON sr.sr_addr_sk = ca_store.ca_address_sk
    JOIN time_dim td_store
        ON sr.sr_return_time_sk = td_store.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td_catalog
        ON cr.cr_returned_time_sk = td_catalog.t_time_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT cp.cp_description, cp.cp_catalog_number
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    ) cp_lateral
    WHERE
        i.i_current_price > 50
        AND i.i_brand_id IN (3, 7, 12)
        AND ca_store.ca_state = 'CA'
        AND td_store.t_meal_time = 'Dinner'
        AND cr.cr_return_amount > 1000
        AND cp_lateral.cp_catalog_number BETWEEN 10 AND 25
        AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
              AND cc.cc_state = 'CA'
        )
)
SELECT
    i_category,
    loss_category,
    cp_catalog_number,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT sr_ticket_number) AS distinct_return_tickets,
    SUM(CASE WHEN i_current_price > 100 THEN cr_return_quantity ELSE 0 END) AS high_price_return_qty
FROM base
GROUP BY i_category, loss_category, cp_catalog_number
HAVING SUM(cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
