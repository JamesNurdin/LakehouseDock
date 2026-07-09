WITH
store_agg AS (
    SELECT
        d.d_year AS yr,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS class,
        s.s_store_name AS channel_name,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY GROUPING SETS (
        (d.d_year, d.d_month_seq, i.i_category, i.i_class, s.s_store_name),
        (d.d_year, d.d_month_seq, i.i_category, i.i_class),
        (d.d_year, d.d_month_seq),
        ()
    )
),
catalog_agg AS (
    SELECT
        d.d_year AS yr,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS class,
        cc.cc_name AS channel_name,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY GROUPING SETS (
        (d.d_year, d.d_month_seq, i.i_category, i.i_class, cc.cc_name),
        (d.d_year, d.d_month_seq, i.i_category, i.i_class),
        (d.d_year, d.d_month_seq),
        ()
    )
),
web_agg AS (
    SELECT
        d.d_year AS yr,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS class,
        w.web_name AS channel_name,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY GROUPING SETS (
        (d.d_year, d.d_month_seq, i.i_category, i.i_class, w.web_name),
        (d.d_year, d.d_month_seq, i.i_category, i.i_class),
        (d.d_year, d.d_month_seq),
        ()
    )
),
combined AS (
    SELECT yr, month_seq, category, class, channel_name, 'Store' AS channel, net_paid, net_profit, txn_cnt FROM store_agg
    UNION ALL
    SELECT yr, month_seq, category, class, channel_name, 'Catalog' AS channel, net_paid, net_profit, txn_cnt FROM catalog_agg
    UNION ALL
    SELECT yr, month_seq, category, class, channel_name, 'Web' AS channel, net_paid, net_profit, txn_cnt FROM web_agg
),
aggregated AS (
    SELECT
        yr,
        month_seq,
        category,
        class,
        channel,
        COALESCE(channel_name,
            CASE channel WHEN 'Store' THEN 'All Stores'
                         WHEN 'Catalog' THEN 'All CallCenters'
                         ELSE 'All WebSites' END) AS channel_name,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(txn_cnt) AS total_txn_cnt
    FROM combined
    GROUP BY ROLLUP (yr, month_seq, category, class, channel, channel_name)
)
SELECT
    yr,
    month_seq,
    category,
    class,
    channel,
    channel_name,
    total_net_paid,
    total_net_profit,
    total_txn_cnt,
    SUM(total_net_profit) OVER (PARTITION BY category, class ORDER BY yr, month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_profit,
    CASE WHEN total_net_paid = 0 THEN 0 ELSE total_net_profit / total_net_paid END AS profit_margin
FROM aggregated
ORDER BY yr, month_seq, category, class, channel
LIMIT 1000
