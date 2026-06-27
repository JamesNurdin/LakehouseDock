WITH sales AS (
    SELECT
        cs_order_number,
        cs_sold_date_sk,
        cs_item_sk,
        cs_net_profit
    FROM catalog_sales
),
returns AS (
    SELECT
        cr_order_number,
        cr_net_loss
    FROM catalog_returns
)
SELECT
    d.d_year,
    i.i_category,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
JOIN date_dim d
    ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY d.d_year, i.i_category
ORDER BY net_profit_after_returns DESC
LIMIT 5
