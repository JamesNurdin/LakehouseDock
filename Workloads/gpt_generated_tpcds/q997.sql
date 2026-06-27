WITH store_sales_agg AS (
    SELECT
        p.p_promo_id,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
store_returns_agg AS (
    SELECT
        p.p_promo_id,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(*) AS store_returns_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
catalog_sales_agg AS (
    SELECT
        p.p_promo_id,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
catalog_returns_agg AS (
    SELECT
        p.p_promo_id,
        SUM(cr.cr_net_loss) AS total_catalog_loss,
        COUNT(*) AS catalog_returns_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
web_sales_agg AS (
    SELECT
        p.p_promo_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
web_returns_agg AS (
    SELECT
        p.p_promo_id,
        SUM(wr.wr_net_loss) AS total_web_loss,
        COUNT(*) AS web_returns_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COALESCE(ssa.total_store_profit, 0.0) + COALESCE(csa.total_catalog_profit, 0.0) + COALESCE(wsa.total_web_profit, 0.0) AS total_profit,
    COALESCE(sra.total_store_loss, 0.0) + COALESCE(cra.total_catalog_loss, 0.0) + COALESCE(wra.total_web_loss, 0.0) AS total_loss,
    COALESCE(ssa.store_sales_cnt, 0) + COALESCE(csa.catalog_sales_cnt, 0) + COALESCE(wsa.web_sales_cnt, 0) AS total_sales_count,
    COALESCE(sra.store_returns_cnt, 0) + COALESCE(cra.catalog_returns_cnt, 0) + COALESCE(wra.web_returns_cnt, 0) AS total_returns_count
FROM promotion p
LEFT JOIN store_sales_agg ssa ON p.p_promo_id = ssa.p_promo_id
LEFT JOIN store_returns_agg sra ON p.p_promo_id = sra.p_promo_id
LEFT JOIN catalog_sales_agg csa ON p.p_promo_id = csa.p_promo_id
LEFT JOIN catalog_returns_agg cra ON p.p_promo_id = cra.p_promo_id
LEFT JOIN web_sales_agg wsa ON p.p_promo_id = wsa.p_promo_id
LEFT JOIN web_returns_agg wra ON p.p_promo_id = wra.p_promo_id
ORDER BY total_profit DESC
LIMIT 100
