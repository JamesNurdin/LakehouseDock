WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_net_loss AS sr_net_loss,
        hd.hd_vehicle_count,
        inv.inv_quantity_on_hand,
        wp.wp_char_count
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND hd.hd_vehicle_count >= 0
      AND inv.inv_quantity_on_hand > 0
      AND wp.wp_char_count > 1000
),
item_agg AS (
    SELECT
        d_year,
        i_category,
        i_item_sk,
        SUM(cr_net_loss + sr_net_loss) AS item_net_loss,
        COUNT(*) AS item_return_cnt
    FROM joined
    GROUP BY d_year, i_category, i_item_sk
)
SELECT
    d_year,
    i_category,
    AVG(item_net_loss) AS avg_item_net_loss,
    SUM(item_return_cnt) AS total_returns
FROM item_agg
GROUP BY d_year, i_category
HAVING AVG(item_net_loss) > 500
ORDER BY avg_item_net_loss DESC
LIMIT 100
