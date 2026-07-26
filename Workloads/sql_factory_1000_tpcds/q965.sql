WITH item_category_sales AS (
    SELECT
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS category_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
 category_returns AS (
    SELECT
        i.i_category,
        SUM(sr.sr_net_loss) AS category_return_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT
    c.i_category,
    c.category_sales,
    COALESCE(r.category_return_loss,0) AS category_return_loss,
    (c.category_sales - COALESCE(r.category_return_loss,0)) AS net_category_revenue,
    c.distinct_transactions,
    NTILE(4) OVER (ORDER BY c.category_sales DESC) AS sales_quartile
FROM item_category_sales c
LEFT JOIN category_returns r ON c.i_category = r.i_category
ORDER BY net_category_revenue DESC
