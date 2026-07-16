WITH sales_by_store_date AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        SUM(ss.ss_quantity) AS quantity_sold,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
returns_by_date AS (
    SELECT
        cr.cr_returned_date_sk,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_return_quantity) AS return_quantity
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
),
inventory_by_date AS (
    SELECT
        inv.inv_date_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk
)

SELECT
    s.s_store_id,
    d.d_date,
    sb.sales_amount,
    COALESCE(rb.return_amount, 0) AS return_amount,
    sb.sales_amount - COALESCE(rb.return_amount, 0) AS net_sales,
    sb.profit_amount,
    ib.avg_quantity_on_hand,
    sb.transaction_count,
    CASE WHEN d_closure.d_date IS NOT NULL THEN 'CLOSED' ELSE 'OPEN' END AS store_status,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d.d_date) AS day_seq,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY sb.sales_amount - COALESCE(rb.return_amount, 0) DESC) AS sales_rank
FROM sales_by_store_date sb
JOIN date_dim d
    ON sb.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON sb.ss_store_sk = s.s_store_sk
LEFT JOIN returns_by_date rb
    ON rb.cr_returned_date_sk = d.d_date_sk
LEFT JOIN inventory_by_date ib
    ON ib.inv_date_sk = d.d_date_sk
LEFT JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d.d_year = 2022
ORDER BY net_sales DESC
LIMIT 100
