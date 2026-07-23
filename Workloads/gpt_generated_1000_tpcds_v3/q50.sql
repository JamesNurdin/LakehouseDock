WITH inventory_agg AS (
    SELECT inv_date_sk,
           inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
store_returns_agg AS (
    SELECT sr.sr_store_sk,
           sr.sr_returned_date_sk,
           SUM(sr.sr_net_loss) AS total_net_loss,
           SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
)
SELECT
    dd.d_date,
    s.s_store_name,
    cc.cc_name AS call_center_name,
    cp.cp_description,
    sm.sm_type AS ship_mode,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    inv_agg.total_on_hand,
    sr_agg.total_net_loss,
    sr_agg.total_return_qty,
    CASE WHEN sr_agg.total_net_loss > 1000 THEN 'High' ELSE 'Medium' END AS net_loss_category,
    DENSE_RANK() OVER (PARTITION BY dd.d_year ORDER BY sr_agg.total_net_loss DESC) AS net_loss_rank_year,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY dd.d_date DESC) AS recent_return_row_num,
    SUM(sr.sr_net_loss) OVER (PARTITION BY s.s_store_sk ORDER BY dd.d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3day_net_loss
FROM inventory_agg inv_agg
JOIN date_dim dd ON inv_agg.inv_date_sk = dd.d_date_sk
JOIN store_returns_agg sr_agg ON dd.d_date_sk = sr_agg.sr_returned_date_sk
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk AND sr.sr_returned_date_sk = dd.d_date_sk
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = dd.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON wp.wp_creation_date_sk = dd.d_date_sk
WHERE dd.d_fy_quarter_seq = 10
  AND cc.cc_mkt_id = 3
  AND sr.sr_fee > 50
ORDER BY dd.d_date DESC, net_loss_rank_year
LIMIT 100
