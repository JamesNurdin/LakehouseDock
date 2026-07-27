WITH sales_agg AS (
    SELECT
        i.i_brand_id AS brand_id,
        i.i_class AS class,
        sm.sm_code AS ship_mode,
        SUM(
            COALESCE(cs.cs_net_profit, 0) +
            COALESCE(ss.ss_net_profit, 0) +
            COALESCE(ws.ws_net_profit, 0) -
            COALESCE(cr.cr_net_loss, 0) -
            COALESCE(wr.wr_net_loss, 0)
        ) AS total_net_profit,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        RANK() OVER (PARTITION BY sm.sm_code ORDER BY SUM(
            COALESCE(cs.cs_net_profit, 0) +
            COALESCE(ss.ss_net_profit, 0) +
            COALESCE(ws.ws_net_profit, 0) -
            COALESCE(cr.cr_net_loss, 0) -
            COALESCE(wr.wr_net_loss, 0)
        ) DESC) AS rank_by_profit
    FROM call_center c
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = c.cc_call_center_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND i.i_item_sk = p.p_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = td.t_time_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.cc_manager IN ('Clyde Scott', 'Travis Wilson')
      AND sm.sm_code IN ('AIR', 'SEA')
      AND i.i_brand_id BETWEEN 1001001 AND 5002002
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 8 AND 17
    GROUP BY i.i_brand_id, i.i_class, sm.sm_code
)
SELECT DISTINCT
    brand_id,
    class,
    ship_mode,
    total_net_profit,
    total_quantity_on_hand,
    rank_by_profit
FROM sales_agg
WHERE rank_by_profit <= 5
ORDER BY ship_mode, rank_by_profit
LIMIT 100
