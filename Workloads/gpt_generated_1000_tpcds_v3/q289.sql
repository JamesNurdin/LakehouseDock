WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc,
        sm.sm_contract,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_return_fee,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        MAX(wp.wp_url) AS sample_web_page_url,
        MAX(ws.web_name) AS sample_web_site_name
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sales.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sales.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_sales.d_year = 2002
      AND s.s_state = 'CA'
      AND r.r_reason_desc = 'Package was damaged'
      AND cr.cr_fee > 50
      AND sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, r.r_reason_desc, sm.sm_contract
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_state,
    a.r_reason_desc,
    a.sm_contract,
    a.total_net_paid,
    a.total_return_amount,
    a.total_return_fee,
    CASE
        WHEN a.total_return_amount > 1000 THEN 'High Returns'
        ELSE 'Low Returns'
    END AS return_level,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY (a.total_net_paid - a.total_return_amount) DESC) AS state_store_rank,
    a.avg_inventory_on_hand,
    a.sample_web_page_url,
    a.sample_web_site_name
FROM aggregated a
ORDER BY a.s_state, state_store_rank
LIMIT 100
