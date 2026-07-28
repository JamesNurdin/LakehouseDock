WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    s.s_store_name,
    i.i_item_id,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
    SUM(inv_agg.total_on_hand) AS inventory_on_hand,
    CASE WHEN SUM(COALESCE(cr.cr_net_loss, 0)) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_loss_category
FROM store_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk                                   -- join rule 1
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk                                 -- join rule 2
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk                                 -- join rule 3
JOIN customer_demographics ss_cd
    ON ss.ss_cdemo_sk = ss_cd.cd_demo_sk                             -- join rule 4
JOIN household_demographics ss_hd
    ON ss.ss_hdemo_sk = ss_hd.hd_demo_sk                             -- join rule 5
JOIN customer_address ss_ca
    ON ss.ss_addr_sk = ss_ca.ca_address_sk                           -- join rule 6
JOIN inv_agg
    ON i.i_item_sk = inv_agg.inv_item_sk                              -- pre‑aggregated CTE
LEFT JOIN catalog_returns cr
    ON i.i_item_sk = cr.cr_item_sk                                    -- join rule 7
LEFT JOIN customer_demographics cr_cd_ref
    ON cr.cr_refunded_cdemo_sk = cr_cd_ref.cd_demo_sk                 -- join rule 8
LEFT JOIN household_demographics cr_hd_ref
    ON cr.cr_refunded_hdemo_sk = cr_hd_ref.hd_demo_sk                 -- join rule 9
LEFT JOIN customer_address cr_ca_ref
    ON cr.cr_refunded_addr_sk = cr_ca_ref.ca_address_sk               -- join rule 10
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk                        -- join rule 11
LEFT JOIN reason cr_r
    ON cr.cr_reason_sk = cr_r.r_reason_sk                             -- join rule 12
LEFT JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk                                    -- join rule 13
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk                         -- join rule 14
LEFT JOIN reason wr_r
    ON wr.wr_reason_sk = wr_r.r_reason_sk                             -- join rule 15
LEFT JOIN customer_demographics wr_cd_ref
    ON wr.wr_refunded_cdemo_sk = wr_cd_ref.cd_demo_sk                 -- join rule 16
LEFT JOIN household_demographics wr_hd_ref
    ON wr.wr_refunded_hdemo_sk = wr_hd_ref.hd_demo_sk                 -- join rule 17
LEFT JOIN customer_address wr_ca_ref
    ON wr.wr_refunded_addr_sk = wr_ca_ref.ca_address_sk               -- join rule 18
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = ss.ss_item_sk                           -- anti‑join using allowed key
)
GROUP BY
    s.s_store_name,
    i.i_item_id
ORDER BY total_sales DESC
LIMIT 100
