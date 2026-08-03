WITH
    cross_set AS (
        SELECT sm.sm_ship_mode_id, v.n
        FROM (SELECT sm_ship_mode_id FROM ship_mode WHERE sm_carrier = 'FEDEX') sm
        CROSS JOIN (VALUES (1), (2), (3)) AS v(n)
    ),
    except_items AS (
        SELECT i_item_sk FROM item WHERE i_units = 'Cup'
        EXCEPT
        SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0
    ),
    main AS (
        SELECT
            i.i_item_id,
            i.i_product_name,
            i.i_item_sk,
            COUNT(DISTINCT ss.ss_ticket_number) AS cnt_sales_tickets,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            AVG(ss.ss_ext_sales_price) AS avg_sales,
            MIN(ss.ss_ext_sales_price) AS min_sales,
            MAX(ss.ss_ext_sales_price) AS max_sales,
            -- correlated scalar subquery for inventory per item
            (SELECT SUM(inv_quantity_on_hand)
             FROM inventory inv
             WHERE inv.inv_item_sk = i.i_item_sk) AS total_inventory,
            -- intersect reason count (store vs catalog)
            (SELECT COUNT(*)
             FROM (
                 SELECT r_sr.r_reason_sk
                 FROM reason r_sr
                 JOIN store_returns sr ON sr.sr_reason_sk = r_sr.r_reason_sk
                 INTERSECT
                 SELECT r_cr.r_reason_sk
                 FROM reason r_cr
                 JOIN catalog_returns cr ON cr.cr_reason_sk = r_cr.r_reason_sk
             ) AS inter) AS intersect_reason_cnt
        FROM
            store_sales ss
            JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
            JOIN item i ON ss.ss_item_sk = i.i_item_sk
            JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
            JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
            JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
            JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
            JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
            JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
            JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
            JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
            JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
            JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
            JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
            JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
            JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
            JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        WHERE
            cc.cc_country = 'United States'
            AND sm.sm_carrier = 'FEDEX'
            AND i.i_units = 'Cup'
            AND t_ss.t_hour BETWEEN 9 AND 17
        GROUP BY
            i.i_item_id,
            i.i_product_name,
            i.i_item_sk
    )
SELECT
    main.*, 
    (SELECT COUNT(*) FROM cross_set) AS cross_set_row_count,
    (SELECT COUNT(*) FROM except_items) AS except_item_cnt
FROM main
ORDER BY total_sales DESC
LIMIT 100
