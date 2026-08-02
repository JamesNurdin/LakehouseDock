WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d1.d_year,
        i.i_item_id,
        i.i_brand,
        cp.cp_catalog_number,
        hd.hd_vehicle_count,
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
        inventory_agg.total_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                           AND cs.cs_sold_date_sk = d1.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                            AND cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_date_sk = d1.d_date_sk
    ) AS inventory_agg
    JOIN web_page wp ON wp.wp_creation_date_sk = d1.d_date_sk
    WHERE d1.d_year = 1998
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cp.cp_catalog_number = 17
      AND hd.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_ticket_number = ss.ss_ticket_number
            AND sr2.sr_return_quantity > 0
      )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d1.d_year,
        i.i_item_id,
        i.i_brand,
        cp.cp_catalog_number,
        hd.hd_vehicle_count,
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc,
        inventory_agg.total_quantity_on_hand
)
SELECT
    base.s_store_id,
    base.s_store_name,
    base.s_state,
    base.d_year,
    base.i_item_id,
    base.i_brand,
    base.cp_catalog_number,
    base.hd_vehicle_count,
    base.cc_name,
    base.sm_type,
    base.r_reason_desc,
    base.total_net_paid,
    base.total_net_profit,
    base.sales_cnt,
    base.total_return_loss,
    base.total_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY base.s_store_id ORDER BY base.total_net_paid DESC) AS store_sales_rank
FROM base
ORDER BY base.total_net_paid DESC
LIMIT 100
