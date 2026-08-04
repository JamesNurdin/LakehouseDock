WITH
    -- Re‑use the date dimension under two different aliases
    d_start AS (
        SELECT *
        FROM date_dim
        WHERE d_year BETWEEN 2000 AND 2001
    ),
    d_end AS (
        SELECT *
        FROM date_dim
        WHERE d_year BETWEEN 2000 AND 2001
    ),

    -- Core fact‑dimensional join that brings together all 11 tables
    base AS (
        SELECT
            cp.cp_catalog_page_id,
            cd.cd_gender,
            hd.hd_vehicle_count,
            s.s_store_name,
            sm.sm_type,
            p.p_promo_name,
            i.inv_quantity_on_hand,
            sr.sr_return_amt,
            ws.ws_net_profit,
            ws.ws_quantity,
            ws.ws_order_number,
            -- correlated scalar subquery: max quantity for the same order
            (SELECT MAX(ws2.ws_quantity)
             FROM web_sales ws2
             WHERE ws2.ws_order_number = ws.ws_order_number) AS max_qty_per_order,
            -- correlated scalar subquery: total return amount for the store of the row
            (SELECT SUM(sr2.sr_return_amt)
             FROM store_returns sr2
             WHERE sr2.sr_store_sk = s.s_store_sk) AS total_store_return,
            -- existence check: is there any promotion with the same name that starts on the catalog start date?
            CASE WHEN EXISTS (
                SELECT 1
                FROM promotion p2
                WHERE p2.p_promo_name = p.p_promo_name
                  AND p2.p_start_date_sk = d_start.d_date_sk
            ) THEN 1 ELSE 0 END AS promo_active_flag
        FROM catalog_page cp
        JOIN d_start          ON cp.cp_start_date_sk = d_start.d_date_sk            -- rule 1
        JOIN d_end            ON cp.cp_end_date_sk   = d_end.d_date_sk            -- rule 2
        JOIN store s          ON s.s_closed_date_sk   = d_end.d_date_sk            -- rule 3
        JOIN store_returns sr ON sr.sr_returned_date_sk = d_end.d_date_sk            -- rule 4
                              AND sr.sr_store_sk        = s.s_store_sk            -- rule 5
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk                -- rule 6
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk                -- rule 7
        JOIN income_band ib   ON hd.hd_income_band_sk = ib.ib_income_band_sk        -- rule 8
        JOIN inventory i      ON i.inv_date_sk = d_start.d_date_sk                    -- rule 9
        JOIN web_sales ws     ON ws.ws_sold_date_sk = d_start.d_date_sk                -- rule 10
                              AND ws.ws_ship_date_sk = d_end.d_date_sk                -- rule 11
        JOIN ship_mode sm     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk               -- rule 12
        JOIN promotion p      ON ws.ws_promo_sk = p.p_promo_sk                        -- rule 13
        WHERE ws.ws_quantity > 0
    ),

    -- Two different slices of the same data set
    u1 AS (
        SELECT * FROM base WHERE ws_quantity >= 2
    ),
    u2 AS (
        SELECT * FROM base WHERE sr_return_amt > 0
    ),

    -- Union of the two slices (distinct rows only)
    union_q AS (
        SELECT * FROM u1
        UNION DISTINCT
        SELECT * FROM u2
    ),

    -- Intersect the catalogue‑page keys that appear in both slices
    intersect_ids AS (
        SELECT cp_catalog_page_id FROM u1
        INTERSECT
        SELECT cp_catalog_page_id FROM u2
    ),

    -- Rank rows per catalogue page, keep only the top‑3 per page
    ranked AS (
        SELECT
            *,
            row_number() OVER (PARTITION BY cp_catalog_page_id ORDER BY ws_net_profit DESC) AS rnk
        FROM union_q
        WHERE cp_catalog_page_id IN (SELECT cp_catalog_page_id FROM intersect_ids)
    ),

    -- Final aggregation, still keeping the rank column
    final_agg AS (
        SELECT
            cp_catalog_page_id,
            cd_gender,
            hd_vehicle_count,
            s_store_name,
            sm_type,
            p_promo_name,
            SUM(inv_quantity_on_hand)      AS total_inventory,
            SUM(sr_return_amt)             AS total_return_amount,
            SUM(ws_net_profit)             AS total_profit,
            MAX(max_qty_per_order)         AS max_quantity_per_order,
            MAX(total_store_return)        AS total_store_return,
            MAX(promo_active_flag)         AS promo_active_flag,
            rnk
        FROM ranked
        GROUP BY
            cp_catalog_page_id,
            cd_gender,
            hd_vehicle_count,
            s_store_name,
            sm_type,
            p_promo_name,
            rnk
    )
SELECT *
FROM final_agg
ORDER BY total_profit DESC
LIMIT 100
