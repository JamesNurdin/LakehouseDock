WITH joined_data AS (
    SELECT
        d.d_date,
        s.s_store_name,
        cc.cc_name,
        i.i_item_id,
        i.i_product_name,
        cr.cr_return_amount,
        cr.cr_net_loss,
        inv.inv_quantity_on_hand,
        ws.web_name,
        cr.cr_fee,
        s.s_state,
        ws.web_class,
        d.d_year
    FROM catalog_returns AS cr
    INNER JOIN date_dim AS d
        ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN item AS i
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN call_center AS cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN inventory AS inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store AS s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site AS ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cr.cr_fee > 20
      AND inv.inv_quantity_on_hand > 100
      AND s.s_state = 'CA'
      AND ws.web_class = 'A'
)
SELECT
    d_date,
    s_store_name,
    cc_name,
    i_item_id,
    i_product_name,
    cr_return_amount,
    cr_net_loss,
    inv_quantity_on_hand,
    web_name,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY cr_net_loss DESC) AS rn_by_net_loss,
    AVG(cr_net_loss) OVER (ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS net_loss_7day_moving_avg
FROM joined_data
ORDER BY d_date, rn_by_net_loss
