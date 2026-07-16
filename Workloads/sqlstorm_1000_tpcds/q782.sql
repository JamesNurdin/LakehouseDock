WITH dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2002-01-01' AND DATE '2002-03-31'
),
sales_combined AS (
    SELECT
        s.s_store_sk AS location_sk,
        s.s_store_name AS location_name,
        s.s_city AS location_city,
        s.s_state AS location_state,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_net_profit AS net_profit,
        'store' AS channel,
        ss.ss_ticket_number AS ticket_number,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price
    FROM store_sales ss
    JOIN dates d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        cc.cc_call_center_sk AS location_sk,
        cc.cc_name AS location_name,
        cc.cc_city AS location_city,
        cc.cc_state AS location_state,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_net_profit AS net_profit,
        'call_center' AS channel,
        cs.cs_order_number AS ticket_number,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price
    FROM catalog_sales cs
    JOIN dates d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT
        ws.ws_web_site_sk AS location_sk,
        we.web_name AS location_name,
        we.web_city AS location_city,
        we.web_state AS location_state,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_net_profit AS net_profit,
        'web' AS channel,
        ws.ws_order_number AS ticket_number,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price
    FROM web_sales ws
    JOIN dates d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
),
returns_combined AS (
    SELECT
        sr.sr_store_sk AS location_sk,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns sr
    JOIN dates d ON sr.sr_returned_date_sk = d.d_date_sk

    UNION ALL

    SELECT
        cr.cr_call_center_sk AS location_sk,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_net_loss AS net_loss,
        'call_center' AS channel
    FROM catalog_returns cr
    JOIN dates d ON cr.cr_returned_date_sk = d.d_date_sk

    UNION ALL

    SELECT
        wr.wr_web_page_sk AS location_sk,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns wr
    JOIN dates d ON wr.wr_returned_date_sk = d.d_date_sk
),
aggregated AS (
    SELECT
        sc.location_sk,
        sc.location_name,
        sc.location_city,
        sc.location_state,
        sc.channel,
        COALESCE(SUM(sc.net_profit), 0) AS total_net_profit,
        COALESCE(SUM(rc.net_loss), 0) AS total_net_loss,
        COUNT(DISTINCT sc.ticket_number) AS num_transactions,
        COUNT(DISTINCT rc.date_sk) AS num_return_dates,
        CASE WHEN sc.location_state IS NULL THEN 'UNKNOWN' ELSE sc.location_state END AS state_coalesce
    FROM sales_combined sc
    LEFT JOIN returns_combined rc
        ON sc.location_sk = rc.location_sk
       AND sc.channel = rc.channel
       AND sc.date_sk = rc.date_sk
    GROUP BY
        sc.location_sk,
        sc.location_name,
        sc.location_city,
        sc.location_state,
        sc.channel
),
state_avg AS (
    SELECT
        state_coalesce,
        channel,
        AVG(total_net_profit - total_net_loss) AS avg_state_channel_profit
    FROM aggregated
    GROUP BY state_coalesce, channel
)
SELECT
    a.location_desc,
    a.channel,
    a.total_net_profit,
    a.total_net_loss,
    (a.total_net_profit - a.total_net_loss) AS net_contribution,
    a.num_transactions,
    CASE WHEN a.num_transactions = 0 THEN NULL ELSE (a.total_net_profit - a.total_net_loss) / a.num_transactions END AS avg_profit_per_txn,
    a.channel_rank,
    sa.avg_state_channel_profit,
    CASE
        WHEN (a.total_net_profit - a.total_net_loss) > sa.avg_state_channel_profit THEN 'ABOVE_AVG'
        WHEN (a.total_net_profit - a.total_net_loss) = sa.avg_state_channel_profit THEN 'EQUAL_AVG'
        ELSE 'BELOW_AVG'
    END AS performance_flag,
    (SELECT COUNT(*) FROM aggregated a2 WHERE a2.channel = a.channel AND (a2.total_net_profit - a2.total_net_loss) > (a.total_net_profit - a.total_net_loss)) AS higher_profit_locations,
    (SELECT MAX(a3.total_net_profit - a3.total_net_loss) FROM aggregated a3 WHERE a3.channel = a.channel) AS channel_max_contribution,
    CASE WHEN regexp_like(a.location_desc, '^.*NY.*$') THEN 'NY_LOCATION' ELSE 'OTHER_LOCATION' END AS location_type_flag
FROM (
    SELECT
        ag.location_name,
        ag.location_city,
        ag.location_state,
        ag.channel,
        ag.total_net_profit,
        ag.total_net_loss,
        ag.num_transactions,
        ag.state_coalesce,
        CONCAT(COALESCE(ag.location_name, ''), ' - ', COALESCE(ag.location_city, ''), ', ', COALESCE(ag.location_state, '')) AS location_desc,
        ROW_NUMBER() OVER (PARTITION BY ag.channel ORDER BY (ag.total_net_profit - ag.total_net_loss) DESC) AS channel_rank
    FROM aggregated ag
) a
LEFT JOIN state_avg sa ON a.state_coalesce = sa.state_coalesce AND a.channel = sa.channel
WHERE a.channel_rank <= 10
ORDER BY a.channel, a.channel_rank
