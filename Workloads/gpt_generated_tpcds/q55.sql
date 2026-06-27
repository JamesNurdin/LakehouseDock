WITH catalog_sales_agg AS (
    SELECT sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_catalog_customers
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
),
web_sales_agg AS (
    SELECT sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
),
returns_by_reason AS (
    SELECT sm.sm_type AS ship_mode_type,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY sm.sm_type, r.r_reason_desc
)
SELECT
    rbr.ship_mode_type,
    rbr.reason_desc,
    COALESCE(cs.total_catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(ws.total_web_net_profit, 0) AS web_net_profit,
    COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
    COALESCE(ws.total_web_sales, 0) AS web_sales,
    (COALESCE(cs.total_catalog_sales, 0) + COALESCE(ws.total_web_sales, 0)) AS total_sales,
    rbr.total_return_loss,
    rbr.total_return_amount,
    rbr.return_transactions,
    CASE
        WHEN (COALESCE(cs.total_catalog_sales, 0) + COALESCE(ws.total_web_sales, 0)) > 0
        THEN rbr.total_return_loss / (COALESCE(cs.total_catalog_sales, 0) + COALESCE(ws.total_web_sales, 0))
        ELSE NULL
    END AS return_loss_ratio
FROM returns_by_reason rbr
LEFT JOIN catalog_sales_agg cs ON rbr.ship_mode_type = cs.ship_mode_type
LEFT JOIN web_sales_agg ws ON rbr.ship_mode_type = ws.ship_mode_type
ORDER BY rbr.ship_mode_type, rbr.reason_desc
