WITH per_item_stats AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        cc.cc_call_center_id,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM time_dim t
    JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk AND cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE
        cd.cd_gender = 'F'
        AND ib.ib_lower_bound >= 50000
        AND i.i_rec_start_date >= DATE '2001-01-01'
        AND sm.sm_type = 'AIR'
        AND cc.cc_gmt_offset BETWEEN -5 AND 0
    GROUP BY
        i.i_item_sk,
        i.i_category,
        cc.cc_call_center_id
)
SELECT
    stats.i_category,
    COUNT(DISTINCT stats.i_item_sk) AS num_items,
    SUM(stats.total_sales) AS category_sales,
    SUM(stats.total_store_returns) AS category_store_returns,
    SUM(stats.total_web_returns) AS category_web_returns,
    SUM(stats.total_inventory) AS category_inventory,
    ROUND((SUM(stats.total_sales) - SUM(stats.total_store_returns) - SUM(stats.total_web_returns)) / NULLIF(SUM(stats.total_sales), 0), 4) AS profit_margin
FROM per_item_stats stats
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_item_sk = stats.i_item_sk
      AND inv2.inv_quantity_on_hand > 1000
)
GROUP BY stats.i_category
HAVING SUM(stats.total_sales) > 10000
ORDER BY profit_margin DESC
LIMIT 20
