WITH store_base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
),
store_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY store_net_profit DESC) AS profit_rank
    FROM store_base
),
web_base AS (
    SELECT
        ws.ws_web_site_sk,
        d.d_year,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_site_sk, d.d_year
),
web_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY web_net_profit DESC) AS profit_rank
    FROM web_base
),
catalog_base AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_call_center_sk, cs.cs_catalog_page_sk, d.d_year
),
catalog_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cs_call_center_sk ORDER BY catalog_net_profit DESC) AS profit_rank
    FROM catalog_base
),
all_sales AS (
    SELECT
        sb.s_store_sk AS entity_sk,
        sb.s_store_name AS entity_name,
        sb.d_year,
        sb.store_net_paid AS net_paid,
        sb.store_net_profit AS net_profit,
        'store' AS entity_type,
        sb.profit_rank
    FROM store_agg sb
    UNION ALL
    SELECT
        wb.ws_web_site_sk,
        CONCAT('WebSite_', CAST(wb.ws_web_site_sk AS VARCHAR)),
        wb.d_year,
        wb.web_net_paid,
        wb.web_net_profit,
        'web_site',
        wb.profit_rank
    FROM web_agg wb
    UNION ALL
    SELECT
        ca.cs_call_center_sk,
        COALESCE(cc.cc_name, 'Unknown_CC'),
        ca.d_year,
        ca.catalog_net_paid,
        ca.catalog_net_profit,
        'call_center',
        ca.profit_rank
    FROM catalog_agg ca
    LEFT JOIN call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk
)
SELECT
    a.entity_type,
    a.entity_name,
    a.d_year,
    a.net_paid,
    a.net_profit,
    a.profit_rank,
    CASE WHEN a.net_profit > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_indicator,
    COALESCE(a.entity_name, 'UNKNOWN') || '_' || CAST(a.d_year AS VARCHAR) AS unique_key,
    (
        SELECT
            SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0))
        FROM
            (SELECT sr.sr_store_sk AS ref_sk, sr.sr_net_loss FROM store_returns sr) sr
            FULL OUTER JOIN
            (SELECT cr.cr_call_center_sk AS ref_sk, cr.cr_net_loss FROM catalog_returns cr) cr
                ON sr.ref_sk = cr.ref_sk
            FULL OUTER JOIN
            (SELECT wr.wr_web_page_sk AS ref_sk, wr.wr_net_loss FROM web_returns wr) wr
                ON COALESCE(sr.ref_sk, cr.ref_sk) = wr.ref_sk
        WHERE
            (a.entity_type = 'store' AND sr.ref_sk = a.entity_sk)
            OR (a.entity_type = 'call_center' AND cr.ref_sk = a.entity_sk)
            OR (a.entity_type = 'web_site' AND wr.ref_sk = a.entity_sk)
    ) AS total_net_loss,
    SUM(a.net_profit) OVER (PARTITION BY a.entity_type ORDER BY a.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit
FROM all_sales a
WHERE
    a.net_paid IS NOT NULL
    AND a.entity_type IN ('store', 'call_center')
    AND a.entity_sk IN (
        SELECT entity_sk FROM all_sales WHERE profit_rank <= 5
        INTERSECT
        SELECT entity_sk FROM all_sales WHERE net_profit > 0
    )
ORDER BY a.entity_type, a.d_year DESC, a.profit_rank
LIMIT 100
