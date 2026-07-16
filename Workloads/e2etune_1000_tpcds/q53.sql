WITH unified_sales AS (
    SELECT
        cc.cc_manager AS manager,
        COALESCE(r.r_reason_desc, 'UNKNOWN') AS reason_desc,
        cs.cs_net_profit AS profit,
        cs.cs_net_paid_inc_tax AS paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN reason r ON cs.cs_promo_sk = r.r_reason_sk
    WHERE cc.cc_manager = 'Bob Belcher'
      AND cs.cs_quantity > 5

    UNION ALL

    SELECT
        'Bob Belcher' AS manager,
        COALESCE(r.r_reason_desc, 'UNKNOWN') AS reason_desc,
        ss.ss_net_profit AS profit,
        ss.ss_net_paid_inc_tax AS paid
    FROM store_sales ss
    LEFT JOIN reason r ON ss.ss_promo_sk = r.r_reason_sk
    WHERE ss.ss_quantity > 5

    UNION ALL

    SELECT
        'Bob Belcher' AS manager,
        COALESCE(r.r_reason_desc, 'UNKNOWN') AS reason_desc,
        ws.ws_net_profit AS profit,
        ws.ws_net_paid_inc_tax AS paid
    FROM web_sales ws
    LEFT JOIN reason r ON ws.ws_promo_sk = r.r_reason_sk
    WHERE ws.ws_quantity > 5
),
aggregated AS (
    SELECT
        manager,
        reason_desc,
        SUM(profit) AS total_profit,
        SUM(paid)   AS total_paid,
        ROUND(100.0 * SUM(profit) / SUM(SUM(profit)) OVER (PARTITION BY manager), 2) AS profit_pct_by_reason
    FROM unified_sales
    GROUP BY manager, reason_desc
    HAVING SUM(profit) > 1000
)
SELECT
    manager,
    reason_desc,
    total_profit,
    total_paid,
    profit_pct_by_reason,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 20
