WITH filtered_store_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ca.ca_state AS state,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_location_type = 'apartment'
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
        )
),
aggregated_store_sales AS (
    SELECT
        sold_date_sk,
        state,
        SUM(ss_net_paid) AS total_net_paid,
        CASE WHEN hd_income_band_sk >= 5 THEN 'High' ELSE 'Low' END AS category,
        'store' AS source
    FROM filtered_store_sales
    GROUP BY sold_date_sk, state, hd_income_band_sk
),
aggregated_web_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        wp.wp_type AS state,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN sm.sm_code = 'EXP' THEN 'Express' ELSE 'Standard' END AS category,
        'web' AS source
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE wp.wp_type = 'article'
    GROUP BY ws.ws_sold_date_sk, wp.wp_type, sm.sm_code
)
SELECT
    sold_date_sk,
    state,
    category,
    total_net_paid,
    source
FROM aggregated_store_sales
UNION ALL
SELECT
    sold_date_sk,
    state,
    category,
    total_net_paid,
    source
FROM aggregated_web_sales
ORDER BY sold_date_sk DESC, total_net_paid DESC
