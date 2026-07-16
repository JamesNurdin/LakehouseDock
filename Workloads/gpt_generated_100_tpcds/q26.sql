WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk
),
combined AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        COALESCE(sa.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(sa.total_sales_net_profit, 0) AS total_sales_net_profit,
        COALESCE(ra.total_return_net_loss, 0) AS total_return_net_loss,
        COALESCE(sa.total_sales_net_profit, 0) - COALESCE(ra.total_return_net_loss, 0) AS net_profit_after_returns,
        CASE
            WHEN COALESCE(sa.total_sales_quantity, 0) = 0 THEN 0
            ELSE ROUND(
                (COALESCE(sa.total_sales_net_profit, 0) - COALESCE(ra.total_return_net_loss, 0))
                / COALESCE(sa.total_sales_quantity, 1), 2
            )
        END AS avg_profit_per_item,
        CASE
            WHEN COALESCE(sa.total_sales_quantity, 0) = 0 THEN 0
            ELSE ROUND(
                COALESCE(ra.total_return_quantity, 0) * 100.0
                / COALESCE(sa.total_sales_quantity, 1), 2
            )
        END AS return_qty_pct
    FROM call_center cc
    LEFT JOIN sales_agg sa ON sa.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN returns_agg ra ON ra.cr_call_center_sk = cc.cc_call_center_sk
)
SELECT
    cc_name,
    total_sales_quantity,
    total_return_quantity,
    total_sales_net_profit,
    total_return_net_loss,
    net_profit_after_returns,
    avg_profit_per_item,
    return_qty_pct,
    RANK() OVER (ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM combined
ORDER BY net_profit_after_returns DESC
LIMIT 10
