/*
Goal: Analyze combined store and web sales performance per item, enriched with customer and location attributes, while filtering on time, price, demographics and promotion activity. The query aggregates profits, transaction counts, categorizes profit level, applies an inventory existence sub‑query, computes a ranking window function, and returns the top results.
*/
WITH agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        cda.ca_state,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM
        store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address cda ON ss.ss_addr_sk = cda.ca_address_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE
        td.t_meal_time IN ('lunch', 'dinner')                     -- filter 1
        AND td.t_minute BETWEEN 5 AND 12                           -- filter 2
        AND i.i_current_price > 50                                 -- filter 3
        AND cd.cd_dep_count >= 2                                   -- filter 4
        AND p.p_discount_active = 'Y'                              -- filter 5
        AND EXISTS (
            SELECT 1
            FROM inventory inv2
            WHERE inv2.inv_item_sk = i.i_item_sk
              AND inv2.inv_quantity_on_hand > 100
        )
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        cda.ca_state,
        cd.cd_gender
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.ca_state,
    a.cd_gender,
    a.total_store_profit,
    a.total_web_profit,
    a.store_transactions,
    a.web_transactions,
    CASE
        WHEN a.total_store_profit + a.total_web_profit > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (
        PARTITION BY a.i_item_id
        ORDER BY a.total_store_profit + a.total_web_profit DESC
    ) AS rn
FROM agg a
ORDER BY a.total_store_profit DESC, a.total_web_profit DESC
LIMIT 100
