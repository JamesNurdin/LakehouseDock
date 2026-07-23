WITH combined_returns AS (
    SELECT
        'store' AS channel,
        s.s_store_id AS location_id,
        s.s_store_name AS location_name,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451215

    UNION ALL

    SELECT
        'web' AS channel,
        sm.sm_ship_mode_id AS location_id,
        sm.sm_type AS location_name,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd2
        ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2
        ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451215
)
SELECT
    channel,
    location_id,
    location_name,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM combined_returns
GROUP BY channel, location_id, location_name
HAVING SUM(net_loss) > (
    SELECT AVG(net_loss) FROM combined_returns
)
ORDER BY total_net_loss DESC
LIMIT 100
