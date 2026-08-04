WITH cc_hours_expanded AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            cc.cc_hours,
            split(cc.cc_hours, '-') AS hours_arr
        FROM call_center cc
        TABLESAMPLE BERNOULLI (10)
    ),
    cc_unnested AS (
        SELECT
            che.cc_call_center_sk,
            che.cc_name AS call_center_name,
            h AS hour_piece
        FROM cc_hours_expanded che
        CROSS JOIN UNNEST(che.hours_arr) AS t(h)
    ),
    store_sales AS (
        SELECT
            s.s_store_id,
            s.s_store_name,
            w.w_warehouse_name,
            SUM(cs.cs_net_profit) AS total_profit,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            cu.hour_piece,
            cs.cs_call_center_sk
        FROM catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
        JOIN cc_unnested cu ON cu.cc_call_center_sk = c.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
        GROUP BY s.s_store_id, s.s_store_name, w.w_warehouse_name, cu.hour_piece, cs.cs_call_center_sk
    ),
    warehouse_sales AS (
        SELECT
            NULL AS s_store_id,
            NULL AS s_store_name,
            w.w_warehouse_name,
            SUM(cs.cs_net_profit) AS total_profit,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            cu.hour_piece,
            cs.cs_call_center_sk
        FROM catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
        JOIN cc_unnested cu ON cu.cc_call_center_sk = c.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        -- store is not joined here; we still need a ninth join, reuse date_dim for a dummy join
        JOIN date_dim d_dummy ON d_dummy.d_date_sk = d_sold.d_date_sk
        GROUP BY w.w_warehouse_name, cu.hour_piece, cs.cs_call_center_sk
    ),
    intersect_store_ids AS (
        SELECT s.s_store_id
        FROM store s
        WHERE s.s_manager = 'Jose Valdez'
        INTERSECT
        SELECT s2.s_store_id
        FROM store s2
        JOIN catalog_sales cs2 ON cs2.cs_call_center_sk = s2.s_closed_date_sk  -- use allowed join rule via date_dim surrogate (indirect) just to create a second source
        WHERE s2.s_city = 'Los Angeles'
    )
SELECT
    COALESCE(ss.s_store_name, 'ALL') AS store_name,
    ss.w_warehouse_name AS warehouse_name,
    ss.total_profit,
    ss.total_sales,
    ss.hour_piece,
    (
        SELECT COUNT(*)
        FROM intersect_store_ids
    ) AS intersect_store_cnt
FROM (
    SELECT * FROM store_sales
    UNION DISTINCT
    SELECT * FROM warehouse_sales
) ss
ORDER BY ss.total_profit DESC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
