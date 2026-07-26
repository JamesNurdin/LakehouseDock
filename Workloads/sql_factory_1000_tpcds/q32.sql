WITH sales_agg AS (
    SELECT
        ca.ca_state,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_quantity) AS sold_qty,
        SUM(ss.ss_net_paid) AS sales_amount,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state, ss.ss_item_sk
),
returns_agg AS (
    SELECT
        ca.ca_state,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_quantity) AS return_qty,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state, cr.cr_item_sk
    UNION ALL
    SELECT
        ca.ca_state,
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_return_quantity) AS return_qty,
        SUM(wr.wr_return_amt) AS return_amount
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state, wr.wr_item_sk
),
returns_combined AS (
    SELECT
        ca_state,
        item_sk,
        SUM(return_qty) AS total_return_qty,
        SUM(return_amount) AS total_return_amount
    FROM returns_agg
    GROUP BY ca_state, item_sk
)
SELECT
    s.ca_state,
    s.item_sk,
    s.sold_qty,
    s.transaction_count,
    COALESCE(r.total_return_qty, 0) AS return_qty,
    s.sales_amount,
    COALESCE(r.total_return_amount, 0) AS return_amount,
    (COALESCE(r.total_return_qty, 0) * 1.0 / s.sold_qty) AS return_rate,
    CASE WHEN (COALESCE(r.total_return_qty, 0) * 1.0 / s.sold_qty) > 0.25 THEN 'High' ELSE 'Low' END AS return_category,
    RANK() OVER (PARTITION BY s.ca_state ORDER BY s.sales_amount DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_combined r ON s.ca_state = r.ca_state AND s.item_sk = r.item_sk
WHERE s.sales_amount > 1000
ORDER BY s.ca_state, sales_rank
LIMIT 20
