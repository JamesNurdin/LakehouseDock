WITH
    store_month AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            'store' AS channel,
            ss.ss_store_sk AS entity_sk,
            SUM(ss.ss_net_paid) AS net_paid,
            SUM(ss.ss_net_profit) AS net_profit,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_month_seq, ss.ss_store_sk
    ),
    catalog_month AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            'catalog' AS channel,
            cs.cs_call_center_sk AS entity_sk,
            SUM(cs.cs_net_paid) AS net_paid,
            SUM(cs.cs_net_profit) AS net_profit,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_month_seq, cs.cs_call_center_sk
    ),
    web_month AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            'web' AS channel,
            ws.ws_web_page_sk AS entity_sk,
            SUM(ws.ws_net_paid) AS net_paid,
            SUM(ws.ws_net_profit) AS net_profit,
            COUNT(*) AS sales_cnt
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_month_seq, ws.ws_web_page_sk
    ),
    combined AS (
        SELECT * FROM store_month
        UNION ALL
        SELECT * FROM catalog_month
        UNION ALL
        SELECT * FROM web_month
    ),
    enriched AS (
        SELECT
            c.d_year,
            c.d_month_seq,
            c.channel,
            COALESCE(st.s_store_name, cc.cc_name, wp.wp_url) AS entity_name,
            c.net_paid,
            c.net_profit,
            c.sales_cnt,
            CASE WHEN c.net_paid = 0 THEN NULL ELSE c.net_profit / c.net_paid END AS profit_margin,
            ROW_NUMBER() OVER (PARTITION BY c.d_year, c.d_month_seq, c.channel ORDER BY CASE WHEN c.net_paid = 0 THEN -1 ELSE c.net_profit / c.net_paid END DESC) AS profit_rank,
            (
                SELECT AVG(c2.net_profit / NULLIF(c2.net_paid, 0))
                FROM combined c2
                WHERE c2.channel = c.channel
                  AND c2.d_month_seq = c.d_month_seq
                  AND c2.d_year < c.d_year
            ) AS prior_years_avg_margin,
            concat(
                COALESCE(st.s_store_name, ''),
                CASE WHEN cc.cc_name IS NOT NULL THEN concat(' - ', cc.cc_name) ELSE '' END,
                CASE WHEN wp.wp_url IS NOT NULL THEN concat(' - ', wp.wp_url) ELSE '' END
            ) AS descriptive_label
        FROM combined c
        LEFT JOIN store st ON c.channel = 'store' AND c.entity_sk = st.s_store_sk
        LEFT JOIN call_center cc ON c.channel = 'catalog' AND c.entity_sk = cc.cc_call_center_sk
        LEFT JOIN web_page wp ON c.channel = 'web' AND c.entity_sk = wp.wp_web_page_sk
    )
SELECT
    e.d_year,
    e.d_month_seq,
    e.channel,
    e.entity_name,
    round(e.net_paid, 2) AS net_paid,
    round(e.net_profit, 2) AS net_profit,
    e.sales_cnt,
    round(e.profit_margin, 4) AS profit_margin,
    e.profit_rank,
    round(e.prior_years_avg_margin, 4) AS prior_years_avg_margin,
    e.descriptive_label
FROM enriched e
WHERE e.profit_margin IS NOT NULL
ORDER BY e.d_year DESC, e.d_month_seq DESC, e.channel, e.profit_rank
LIMIT 100
