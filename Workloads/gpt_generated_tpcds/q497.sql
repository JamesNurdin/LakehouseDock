WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_description,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(cr.cr_order_number) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_page cp
    JOIN catalog_returns cr
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Electronics'
    GROUP BY cp.cp_catalog_page_sk,
             cp.cp_department,
             cp.cp_type,
             cp.cp_catalog_number,
             cp.cp_catalog_page_number,
             cp.cp_description
)
SELECT
    cp_catalog_page_sk,
    cp_department,
    cp_type,
    cp_catalog_number,
    cp_catalog_page_number,
    cp_description,
    total_return_quantity,
    total_return_amount,
    total_net_loss,
    total_returns,
    distinct_orders,
    total_return_amount / NULLIF(total_return_quantity, 0) AS avg_return_amount_per_item,
    total_return_amount / NULLIF(total_returns, 0) AS avg_return_amount_per_return,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM page_returns
ORDER BY total_return_amount DESC
LIMIT 10
