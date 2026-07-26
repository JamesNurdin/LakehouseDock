WITH sales AS (
    SELECT
        hd.hd_demo_sk,
        SUM(ss.ss_quantity) AS total_sales_qty
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk
),
returns AS (
    SELECT
        hd.hd_demo_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk
)
SELECT
    s.hd_demo_sk,
    s.total_sales_qty,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    CASE
        WHEN s.total_sales_qty = 0 THEN 0
        ELSE COALESCE(r.total_return_qty, 0) * 1.0 / s.total_sales_qty
    END AS return_to_sales_ratio,
    PERCENT_RANK() OVER (ORDER BY CASE
        WHEN s.total_sales_qty = 0 THEN 0
        ELSE COALESCE(r.total_return_qty, 0) * 1.0 / s.total_sales_qty
    END) AS ratio_percentile,
    CASE
        WHEN CASE
            WHEN s.total_sales_qty = 0 THEN 0
            ELSE COALESCE(r.total_return_qty, 0) * 1.0 / s.total_sales_qty
        END > 0.5 THEN 'High Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM sales s
LEFT JOIN returns r ON s.hd_demo_sk = r.hd_demo_sk
ORDER BY return_to_sales_ratio DESC
LIMIT 20
