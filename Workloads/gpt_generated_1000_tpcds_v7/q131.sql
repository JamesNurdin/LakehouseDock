WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_hand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND (w.w_warehouse_sk IS NOT NULL AND inv.inv_warehouse_sk = w.w_warehouse_sk)
    WHERE s.s_state = 'CA'
      AND p.p_purpose = 'Unknown'
      AND ss.ss_list_price > 20
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        p.p_promo_name
)
SELECT *
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
