WITH base AS (
    SELECT
        dr.d_year,
        dr.d_date,
        it.i_item_id,
        it.i_product_name,
        wh.w_state,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_net_loss AS catalog_net_loss,
        inv.inv_quantity_on_hand,
        it.i_current_price,
        (SELECT avg(i2.i_current_price) FROM item i2) AS avg_price
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item it ON sr.sr_item_sk = it.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = it.i_item_sk
        AND cr.cr_returned_date_sk = dr.d_date_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
    JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = it.i_item_sk
        AND inv.inv_date_sk = dr.d_date_sk
        AND inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE dr.d_year BETWEEN 2000 AND 2002
      AND it.i_current_price > 50
      AND wh.w_state = 'CA'
      AND cd.cd_marital_status = 'M'
      AND NOT EXISTS (
          SELECT 1 FROM inventory inv2
          WHERE inv2.inv_item_sk = it.i_item_sk
            AND inv2.inv_date_sk = dr.d_date_sk
            AND inv2.inv_quantity_on_hand > 800
      )
)
SELECT
    d_year,
    d_date,
    i_item_id,
    i_product_name,
    w_state,
    store_net_loss,
    catalog_net_loss,
    (store_net_loss + catalog_net_loss) AS total_net_loss,
    inv_quantity_on_hand,
    avg_price,
    RANK() OVER (PARTITION BY d_year ORDER BY (store_net_loss + catalog_net_loss) DESC) AS loss_rank
FROM base
ORDER BY d_year, loss_rank
LIMIT 100
