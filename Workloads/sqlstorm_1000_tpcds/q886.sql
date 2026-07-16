SELECT
    channel,
    state,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit
FROM (
    SELECT
        'Web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws_site.web_state AS state
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        'Store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        s.s_state AS state
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        'Catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cc.cc_state AS state
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
) t
GROUP BY
    channel,
    state
ORDER BY
    total_net_profit DESC,
    channel
LIMIT 50
