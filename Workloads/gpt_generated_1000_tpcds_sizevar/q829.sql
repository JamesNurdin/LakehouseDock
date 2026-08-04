WITH
    -- Store channel with deep joins and a lateral subquery
    store_part AS (
        SELECT
            s.s_store_id,
            i_store.i_item_id,
            ss.ss_ticket_number,
            ss.ss_net_profit,
            p_store.p_discount_active,
            inv_agg.total_inventory,
            CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
            cr.cr_net_loss,
            cc.cc_name AS call_center_name,
            r.r_reason_desc
        FROM store_sales ss
        JOIN store s
          ON ss.ss_store_sk = s.s_store_sk
        JOIN item i_store
          ON ss.ss_item_sk = i_store.i_item_sk
        JOIN promotion p_store
          ON ss.ss_promo_sk = p_store.p_promo_sk
        -- join catalog_returns (via the same item) to bring in reason and call_center
        JOIN catalog_returns cr
          ON i_store.i_item_sk = cr.cr_item_sk
        JOIN call_center cc
          ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN reason r
          ON cr.cr_reason_sk = r.r_reason_sk
        -- lateral subquery to get total inventory for the item
        CROSS JOIN LATERAL (
            SELECT SUM(inv_quantity_on_hand) AS total_inventory
            FROM inventory inv
            WHERE inv.inv_item_sk = i_store.i_item_sk
        ) inv_agg
        WHERE EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = i_store.i_item_sk
              AND cr2.cr_net_loss > 0
        )
    ),
    -- Web channel with its own set of joins
    web_part AS (
        SELECT
            wsite.web_site_id,
            i_web.i_item_id,
            ws.ws_order_number,
            ws.ws_net_profit,
            p_web.p_discount_active,
            CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
        FROM web_sales ws
        JOIN web_site wsite
          ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN item i_web
          ON ws.ws_item_sk = i_web.i_item_sk
        JOIN promotion p_web
          ON ws.ws_promo_sk = p_web.p_promo_sk
        WHERE EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_item_sk = ws.ws_item_sk
        )
    ),
    -- Items that appear in BOTH store and web sales (INTERSECT)
    intersect_items AS (
        SELECT i_store.i_item_sk
        FROM store_sales ss
        JOIN item i_store ON ss.ss_item_sk = i_store.i_item_sk
        INTERSECT
        SELECT i_web.i_item_sk
        FROM web_sales ws
        JOIN item i_web ON ws.ws_item_sk = i_web.i_item_sk
    ),
    -- Combine the two channels, force a dedup with UNION DISTINCT
    combined AS (
        SELECT
            'store' AS channel,
            sp.s_store_id      AS entity_id,
            sp.i_item_id,
            SUM(sp.ss_net_profit)     AS total_profit,
            SUM(sp.total_inventory)   AS total_inventory,
            ROW_NUMBER() OVER (PARTITION BY sp.s_store_id ORDER BY SUM(sp.ss_net_profit) DESC) AS rank_in_entity,
            MAX(sp.profit_flag)       AS profit_flag
        FROM store_part sp
        JOIN intersect_items ii
          ON sp.i_item_id = (
                SELECT i.i_item_id
                FROM item i
                WHERE i.i_item_sk = ii.i_item_sk
          )
        GROUP BY sp.s_store_id, sp.i_item_id
        UNION DISTINCT
        SELECT
            'web' AS channel,
            wp.web_site_id    AS entity_id,
            wp.i_item_id,
            SUM(wp.ws_net_profit)     AS total_profit,
            NULL                       AS total_inventory,
            ROW_NUMBER() OVER (PARTITION BY wp.web_site_id ORDER BY SUM(wp.ws_net_profit) DESC) AS rank_in_entity,
            MAX(wp.profit_flag)       AS profit_flag
        FROM web_part wp
        JOIN intersect_items ii
          ON wp.i_item_id = (
                SELECT i.i_item_id
                FROM item i
                WHERE i.i_item_sk = ii.i_item_sk
          )
        GROUP BY wp.web_site_id, wp.i_item_id
    )
SELECT *
FROM combined
ORDER BY total_profit DESC
LIMIT 100
