WITH agg AS (
    SELECT
        cc.cc_name,
        i.i_category,
        cd.cd_gender,
        hd.hd_vehicle_count,
        SUM(sr.sr_net_loss) AS store_loss,
        SUM(wr.wr_net_loss) AS web_loss,
        SUM(cr.cr_net_loss) AS catalog_loss,
        SUM(sr.sr_net_loss + wr.wr_net_loss + cr.cr_net_loss) AS total_loss,
        (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_category = i.i_category) AS max_price_in_category
    FROM call_center cc
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON i.i_item_sk = cr.cr_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    WHERE cc.cc_manager = 'Jason Brito'
      AND cc.cc_mkt_id IN (1, 5, 6)
      AND i.i_units = 'Box'
      AND inv.inv_quantity_on_hand > 100
      AND sr.sr_return_tax > 20
      AND wr.wr_return_tax BETWEEN 10 AND 50
    GROUP BY GROUPING SETS (
        (cc.cc_name, i.i_category, cd.cd_gender, hd.hd_vehicle_count),
        (cc.cc_name, i.i_category),
        (cc.cc_name),
        ()
    )
)
SELECT
    cc_name,
    i_category,
    cd_gender,
    hd_vehicle_count,
    store_loss,
    web_loss,
    catalog_loss,
    total_loss,
    max_price_in_category,
    CASE WHEN total_loss > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_flag,
    RANK() OVER (ORDER BY total_loss DESC) AS loss_rank
FROM agg
ORDER BY loss_rank
LIMIT 100
