/* goal: Compare aggregated catalog sales and returns per item, classify profit/return severity, then combine with a small set of ship modes and attach the most costly return reason per item */
WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451919
    GROUP BY cs.cs_item_sk, i.i_product_name
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        i.i_product_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS return_severity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451910 AND 2451919
    GROUP BY cr.cr_item_sk, i.i_product_name
),
combined AS (
    SELECT
        'sale'   AS record_type,
        s.cs_item_sk      AS item_sk,
        s.i_product_name  AS product_name,
        s.total_net_paid  AS amount,
        s.profit_category AS category
    FROM sales_agg s
    UNION ALL
    SELECT
        'return' AS record_type,
        r.cr_item_sk      AS item_sk,
        r.i_product_name  AS product_name,
        r.total_return_amount AS amount,
        r.return_severity AS category
    FROM returns_agg r
)
SELECT
    c.record_type,
    c.item_sk,
    c.product_name,
    c.amount,
    c.category,
    sm.sm_ship_mode_id,
    rl.r_reason_desc
FROM combined c
-- cross‑join a small dimension (first 3 ship modes of type 'AIR')
CROSS JOIN (
    SELECT sm_ship_mode_id
    FROM ship_mode
    WHERE sm_type = 'AIR'
    LIMIT 3
) sm
-- lateral subquery to fetch the most expensive return reason for the item (if any)
CROSS JOIN LATERAL (
    SELECT r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_item_sk = c.item_sk
    ORDER BY cr.cr_return_amount DESC
    LIMIT 1
) rl
ORDER BY c.amount DESC
LIMIT 100
