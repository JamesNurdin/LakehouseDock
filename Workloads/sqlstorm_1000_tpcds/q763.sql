WITH union_sales AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           s.s_state AS state,
           'store' AS channel,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           cc.cc_state,
           'catalog',
           cs.cs_net_paid,
           cs.cs_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           w.web_state,
           'web',
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
)
SELECT
    year,
    month,
    state,
    channel,
    total_paid,
    total_profit,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY state, channel ORDER BY total_paid DESC) AS rank_by_state_channel
FROM (
    SELECT
        year,
        month,
        state,
        channel,
        SUM(net_paid) AS total_paid,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM union_sales
    GROUP BY year, month, state, channel
) agg
ORDER BY total_paid DESC
LIMIT 100
