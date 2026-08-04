WITH intersect_items AS (
    SELECT i.i_item_id
    FROM item i
    WHERE i.i_current_price > 20
    INTERSECT
    SELECT CAST(ws.ws_item_sk AS VARCHAR)
    FROM web_sales ws
    WHERE ws.ws_net_paid > 100
),
base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        ca.ca_state,
        ca.ca_country,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        st.s_store_name,
        w.w_warehouse_name,
        w.w_state,
        sm.sm_carrier,
        r.r_reason_desc,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ws.ws_quantity,
        ws.ws_net_paid,
        cp.cp_catalog_number,
        ARRAY[ss.ss_quantity, ws.ws_quantity] AS qty_array
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE
        sm.sm_carrier IN ('RUPEKSA', 'DIAMOND')
        AND w.w_state = 'CA'
        AND i.i_current_price > 10
        AND ib.ib_upper_bound < 100000
        AND ca.ca_country = 'United States'
        AND cp.cp_catalog_number BETWEEN 10 AND 30
        AND i.i_item_id IN (SELECT i_item_id FROM intersect_items)
),
final AS (
    SELECT
        b.s_store_name,
        b.i_item_id,
        b.i_category,
        b.i_brand,
        b.ca_state,
        b.sm_carrier,
        b.w_warehouse_name,
        b.cr_return_amount,
        (SELECT SUM(inv2.inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_item_sk = b.ss_item_sk) AS total_inventory_qty,
        qty AS individual_quantity,
        RANK() OVER (PARTITION BY b.s_store_name ORDER BY b.ss_net_paid DESC) AS sales_rank
    FROM base b
    CROSS JOIN UNNEST(b.qty_array) AS t(qty)
)
SELECT *
FROM final
ORDER BY sales_rank, s_store_name, i_item_id
LIMIT 100
