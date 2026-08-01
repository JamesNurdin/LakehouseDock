WITH
    -- 1. Sample a fraction of items (Bernoulli 10%) and filter on class and start date
    sampled_items AS (
        SELECT i_item_sk,
               i_item_desc,
               i_current_price,
               i_class,
               i_rec_start_date
        FROM item
        TABLESAMPLE BERNOULLI (10)
        WHERE i_class IN ('decor', 'pants')
          AND i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
    ),

    -- 2. Store return facts aggregated with GROUPING SETS
    store_data AS (
        SELECT
            sr.sr_returned_date_sk,
            d.d_year,
            i.i_item_sk,
            i.i_item_desc,
            r.r_reason_desc,
            'store' AS channel,
            SUM(sr.sr_net_loss)        AS net_loss,
            SUM(sr.sr_return_quantity) AS return_qty
        FROM store_returns sr
        JOIN date_dim d   ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t   ON sr.sr_return_time_sk = t.t_time_sk
        JOIN item i       ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r     ON sr.sr_reason_sk = r.r_reason_sk
        JOIN store s      ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        GROUP BY GROUPING SETS (
            (sr.sr_returned_date_sk, d.d_year, i.i_item_sk, i.i_item_desc, r.r_reason_desc),
            (sr.sr_returned_date_sk, d.d_year, r.r_reason_desc)
        )
    ),

    -- 3. Catalog return facts aggregated with GROUPING SETS
    catalog_data AS (
        SELECT
            cr.cr_returned_date_sk,
            d.d_year,
            i.i_item_sk,
            i.i_item_desc,
            r.r_reason_desc,
            'catalog' AS channel,
            SUM(cr.cr_net_loss)        AS net_loss,
            SUM(cr.cr_return_quantity) AS return_qty
        FROM catalog_returns cr
        JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t   ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN item i       ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r     ON cr.cr_reason_sk = r.r_reason_sk
        JOIN call_center cc      ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w         ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
        GROUP BY GROUPING SETS (
            (cr.cr_returned_date_sk, d.d_year, i.i_item_sk, i.i_item_desc, r.r_reason_desc),
            (cr.cr_returned_date_sk, d.d_year, r.r_reason_desc)
        )
    ),

    -- 4. Web return facts aggregated with GROUPING SETS
    web_data AS (
        SELECT
            wr.wr_returned_date_sk,
            d.d_year,
            i.i_item_sk,
            i.i_item_desc,
            r.r_reason_desc,
            'web' AS channel,
            SUM(wr.wr_net_loss)        AS net_loss,
            SUM(wr.wr_return_quantity) AS return_qty
        FROM web_returns wr
        JOIN date_dim d   ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t   ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN item i       ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r     ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_page wp  ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN customer_address ca_return ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
        GROUP BY GROUPING SETS (
            (wr.wr_returned_date_sk, d.d_year, i.i_item_sk, i.i_item_desc, r.r_reason_desc),
            (wr.wr_returned_date_sk, d.d_year, r.r_reason_desc)
        )
    ),

    -- 5. Inventory snapshot (joined but not used directly in final aggregation)
    inventory_data AS (
        SELECT
            i.i_item_sk,
            w.w_warehouse_sk,
            d.d_year,
            SUM(inv.inv_quantity_on_hand) AS qty_on_hand
        FROM inventory inv
        JOIN date_dim d   ON inv.inv_date_sk = d.d_date_sk
        JOIN item i       ON inv.inv_item_sk = i.i_item_sk
        JOIN warehouse w  ON inv.inv_warehouse_sk = w.w_warehouse_sk
        GROUP BY i.i_item_sk, w.w_warehouse_sk, d.d_year
    ),

    -- 6. Web site information (joined via open date)
    web_site_data AS (
        SELECT ws.web_site_id,
               ws.web_name,
               d.d_year
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
        WHERE ws.web_country = 'United States'
    ),

    -- 7. Union of store and catalog returns
    combined_returns AS (
        SELECT * FROM store_data
        UNION ALL
        SELECT * FROM catalog_data
    ),

    -- 8. Intersect with web returns to keep only common reason‑year combos
    intersected AS (
        SELECT channel,
               r_reason_desc,
               net_loss,
               return_qty
        FROM combined_returns
        INTERSECT
        SELECT channel,
               r_reason_desc,
               net_loss,
               return_qty
        FROM web_data
    ),

    -- 9. Reasons that never appear in catalog returns (EXCEPT)
    unused_reasons AS (
        SELECT r.r_reason_sk,
               r.r_reason_desc
        FROM reason r
        EXCEPT
        SELECT cr.cr_reason_sk,
               r.r_reason_desc
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    ),

    -- 10. Full outer join store and web aggregates on year & reason
    full_joined AS (
        SELECT
            COALESCE(s.d_year, w.d_year)            AS year,
            COALESCE(s.r_reason_desc, w.r_reason_desc) AS reason,
            s.net_loss AS store_net_loss,
            w.net_loss AS web_net_loss
        FROM store_data s
        FULL OUTER JOIN web_data w
          ON s.r_reason_desc = w.r_reason_desc
         AND s.d_year = w.d_year
    ),

    -- 11. Final aggregation with CASE, window rank and LATERAL lookup
    final_agg AS (
        SELECT
            fj.year,
            fj.reason,
            COALESCE(fj.store_net_loss, 0) + COALESCE(fj.web_net_loss, 0) AS total_net_loss,
            CASE
                WHEN COALESCE(fj.store_net_loss, 0) + COALESCE(fj.web_net_loss, 0) > 10000 THEN 'HIGH'
                WHEN COALESCE(fj.store_net_loss, 0) + COALESCE(fj.web_net_loss, 0) > 1000  THEN 'MEDIUM'
                ELSE 'LOW'
            END AS loss_category,
            ROW_NUMBER() OVER (PARTITION BY 
                                   CASE
                                       WHEN COALESCE(fj.store_net_loss, 0) + COALESCE(fj.web_net_loss, 0) > 10000 THEN 'HIGH'
                                       WHEN COALESCE(fj.store_net_loss, 0) + COALESCE(fj.web_net_loss, 0) > 1000  THEN 'MEDIUM'
                                       ELSE 'LOW'
                                   END
                               ORDER BY COALESCE(fj.store_net_loss, 0) + COALESCE(fj.web_net_loss, 0) DESC) AS loss_rank,
            -- LATERAL sub‑query: total quantity on hand for the class implied by the loss bucket
            lt.total_qty_on_hand
        FROM full_joined fj
        CROSS JOIN LATERAL (
            SELECT SUM(inv.qty_on_hand) AS total_qty_on_hand
            FROM inventory_data inv
            JOIN item i2 ON inv.i_item_sk = i2.i_item_sk
            WHERE (CASE
                       WHEN COALESCE(fj.store_net_loss, 0) + COALESCE(fj.web_net_loss, 0) > 10000 THEN 'decor'
                       ELSE 'pants'
                   END) = i2.i_class
        ) lt
        WHERE fj.reason IS NOT NULL
    )
SELECT
    fa.year,
    fa.reason,
    fa.total_net_loss,
    fa.loss_category,
    fa.loss_rank,
    fa.total_qty_on_hand,
    -- scalar sub‑query counting decor items in the sample
    (SELECT COUNT(*) FROM sampled_items si WHERE si.i_class = 'decor') AS decor_item_count,
    -- scalar sub‑query counting websites open in the same year
    (SELECT COUNT(*) FROM web_site_data ws WHERE ws.d_year = fa.year) AS websites_open_in_year
FROM final_agg fa
ORDER BY fa.total_net_loss DESC
LIMIT 100
