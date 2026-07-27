WITH base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_rec_end_date,
        sr.sr_return_quantity,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        inv.inv_quantity_on_hand,
        cc.cc_name,
        cc.cc_division,
        p.p_channel_catalog,
        p.p_channel_email,
        ca.ca_city,
        ca.ca_state
    FROM
        store_returns sr
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        JOIN promotion p
            ON p.p_item_sk = i.i_item_sk
        JOIN catalog_returns cr
            ON cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        i.i_rec_end_date >= DATE '2000-01-01'
        AND i.i_rec_end_date <= DATE '2000-12-31'
        AND cc.cc_division IN (1, 3, 5)
        AND p.p_channel_catalog = 'N'
        AND inv.inv_quantity_on_hand > 100
        AND sr.sr_return_quantity > 1
        AND cr.cr_return_amount > 100.0
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_channel_email = 'Y'
        )
)
SELECT
    i_item_id,
    i_product_name,
    cc_name,
    SUM(sr_net_loss) AS total_store_loss,
    SUM(cr_net_loss) AS total_catalog_loss,
    (SUM(sr_net_loss) + SUM(cr_net_loss)) AS total_loss,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    (AVG(inv_quantity_on_hand) - (SELECT avg(inv_quantity_on_hand) FROM inventory)) AS inventory_vs_avg,
    CASE
        WHEN (SUM(sr_net_loss) + SUM(cr_net_loss)) > 1000 THEN 'High'
        WHEN (SUM(sr_net_loss) + SUM(cr_net_loss)) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    DENSE_RANK() OVER (ORDER BY (SUM(sr_net_loss) + SUM(cr_net_loss)) DESC) AS loss_rank
FROM
    base
GROUP BY
    i_item_id,
    i_product_name,
    cc_name
ORDER BY
    loss_rank,
    i_item_id
LIMIT 100
