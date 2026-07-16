WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
),
returns_agg AS (
    SELECT
        cr_call_center_sk,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS distinct_returns
    FROM catalog_returns
    GROUP BY cr_call_center_sk, cr_returned_date_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d.d_date AS transaction_date,
    dccclosed.d_date AS cc_closed_date,
    dccopen.d_date AS cc_open_date,
    dstoreclosed.d_date AS store_closed_date,
    sa.total_sales,
    ra.total_returns,
    (sa.total_sales - ra.total_returns) AS net_sales,
    sa.distinct_tickets,
    ra.distinct_returns
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
JOIN returns_agg ra
    ON ra.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON ra.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dccclosed
    ON cc.cc_closed_date_sk = dccclosed.d_date_sk
JOIN date_dim dccopen
    ON cc.cc_open_date_sk = dccopen.d_date_sk
JOIN date_dim dstoreclosed
    ON s.s_closed_date_sk = dstoreclosed.d_date_sk
WHERE d.d_year = 2001
ORDER BY net_sales DESC
LIMIT 100
