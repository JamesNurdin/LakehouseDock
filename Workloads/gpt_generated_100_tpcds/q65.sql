WITH
    cs_base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_promo_sk,
            cs.cs_call_center_sk,
            cs.cs_net_paid,
            cs.cs_net_profit
        FROM catalog_sales cs
    ),
    cs_join AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            p.p_promo_name,
            cc.cc_name,
            cs_base.cs_net_paid,
            cs_base.cs_net_profit
        FROM cs_base
        JOIN date_dim d ON cs_base.cs_sold_date_sk = d.d_date_sk
        JOIN promotion p ON cs_base.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs_base.cs_call_center_sk = cc.cc_call_center_sk
    ),
    ws_base AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_promo_sk,
            ws.ws_web_site_sk,
            ws.ws_net_paid,
            ws.ws_net_profit
        FROM web_sales ws
    ),
    ws_join AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            p.p_promo_name,
            w.web_name,
            ws_base.ws_net_paid,
            ws_base.ws_net_profit
        FROM ws_base
        JOIN date_dim d ON ws_base.ws_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ws_base.ws_promo_sk = p.p_promo_sk
        JOIN web_site w ON ws_base.ws_web_site_sk = w.web_site_sk
    ),
    combined AS (
        SELECT
            d_year,
            d_month_seq,
            p_promo_name,
            cs_net_paid,
            cs_net_profit,
            CAST(NULL AS decimal(7,2)) AS ws_net_paid,
            CAST(NULL AS decimal(7,2)) AS ws_net_profit
        FROM cs_join
        UNION ALL
        SELECT
            d_year,
            d_month_seq,
            p_promo_name,
            CAST(NULL AS decimal(7,2)) AS cs_net_paid,
            CAST(NULL AS decimal(7,2)) AS cs_net_profit,
            ws_net_paid,
            ws_net_profit
        FROM ws_join
    ),
    agg AS (
        SELECT
            d_year,
            d_month_seq,
            p_promo_name,
            SUM(cs_net_paid) AS total_cs_net_paid,
            SUM(cs_net_profit) AS total_cs_net_profit,
            SUM(ws_net_paid) AS total_ws_net_paid,
            SUM(ws_net_profit) AS total_ws_net_profit
        FROM combined
        GROUP BY d_year, d_month_seq, p_promo_name
    )
SELECT
    d_year,
    d_month_seq,
    p_promo_name,
    total_cs_net_paid,
    total_cs_net_profit,
    total_ws_net_paid,
    total_ws_net_profit,
    COALESCE(total_cs_net_paid, 0) + COALESCE(total_ws_net_paid, 0) AS total_net_paid,
    COALESCE(total_cs_net_profit, 0) + COALESCE(total_ws_net_profit, 0) AS total_net_profit
FROM agg
ORDER BY d_year, d_month_seq, p_promo_name
