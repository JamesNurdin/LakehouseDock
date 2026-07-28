WITH unified_sales AS (
    -- Store sales (with left join to store)
    SELECT
        ss.ss_promo_sk               AS promo_sk,
        p.p_promo_name               AS promo_name,
        NULL                         AS ship_mode_code,
        NULL                         AS reason_desc,
        ss.ss_sold_date_sk           AS sold_date_sk,
        ss.ss_quantity               AS quantity,
        ss.ss_net_profit             AS net_profit,
        td.t_hour                    AS hour
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 18               -- filter 1: business hours
      AND p.p_discount_active = 'Y'                -- filter 2: active promotions
      AND s.s_state = 'CA'                         -- filter 3: stores in CA

    UNION ALL

    -- Web sales (inner joins, includes ship mode and web page)
    SELECT
        ws.ws_promo_sk               AS promo_sk,
        p.p_promo_name               AS promo_name,
        sm.sm_code                   AS ship_mode_code,
        NULL                         AS reason_desc,
        ws.ws_sold_date_sk           AS sold_date_sk,
        ws.ws_quantity               AS quantity,
        ws.ws_net_profit             AS net_profit,
        td.t_hour                    AS hour
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 18               -- filter 1 repeated for consistency
      AND p.p_discount_active = 'Y'                -- filter 2 reproduced
      AND sm.sm_code = 'AIR'                       -- filter 3: only air shipments

    UNION ALL

    -- Catalog returns (left joins to ship mode and reason)
    SELECT
        NULL                         AS promo_sk,
        NULL                         AS promo_name,
        sm.sm_code                   AS ship_mode_code,
        r.r_reason_desc              AS reason_desc,
        cr.cr_returned_date_sk       AS sold_date_sk,
        cr.cr_return_quantity        AS quantity,
        -cr.cr_net_loss              AS net_profit,
        td.t_hour                    AS hour
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 9 AND 18               -- same hour filter
      AND cr.cr_return_quantity > 0               -- filter: only actual returns
      AND sm.sm_contract = 'uukTktPYycct8'         -- filter: specific contract code
)
SELECT
    promo_name,
    ship_mode_code,
    reason_desc,
    SUM(net_profit) AS total_net_profit,
    AVG(quantity)  AS avg_quantity
FROM unified_sales
GROUP BY
    promo_name,
    ship_mode_code,
    reason_desc
HAVING SUM(net_profit) > 1000                     -- keep only profitable groups
ORDER BY total_net_profit DESC
LIMIT 100
