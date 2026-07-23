SELECT
    sold_date_sk,
    channel,
    net_paid_inc_tax,
    quantity,
    store_name,
    promo_name,
    ship_mode_type,
    warehouse_name,
    has_email_promo,
    max_promo_cost
FROM (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        CAST('Store' AS varchar) AS channel,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss.ss_quantity AS quantity,
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        CAST(NULL AS varchar) AS ship_mode_type,
        CAST(NULL AS varchar) AS warehouse_name,
        CASE WHEN EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_promo_sk = ss.ss_promo_sk
              AND p2.p_channel_email = 'Y'
        ) THEN 1 ELSE 0 END AS has_email_promo,
        (SELECT MAX(p3.p_cost) FROM promotion p3 WHERE p3.p_promo_sk = ss.ss_promo_sk) AS max_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_rec_start_date >= DATE '2000-01-01'
      AND s.s_rec_end_date <= DATE '2005-12-31'

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        CAST('Web' AS varchar) AS channel,
        ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
        ws.ws_quantity AS quantity,
        CAST(NULL AS varchar) AS store_name,
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name AS warehouse_name,
        CASE WHEN EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
              AND p2.p_channel_email = 'Y'
        ) THEN 1 ELSE 0 END AS has_email_promo,
        (SELECT MAX(p3.p_cost) FROM promotion p3 WHERE p3.p_promo_sk = ws.ws_promo_sk) AS max_promo_cost
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_rec_end_date <= DATE '2005-12-31'
) AS combined
ORDER BY sold_date_sk DESC, channel
LIMIT 100
