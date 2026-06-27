WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_promo_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number, cr.cr_item_sk
),
sales_with_returns AS (
    SELECT
        s.cs_order_number,
        s.cs_item_sk,
        s.cs_sold_date_sk,
        s.cs_quantity,
        s.cs_net_profit,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.cs_promo_sk
    FROM sales s
    LEFT JOIN returns r
        ON s.cs_order_number = r.cr_order_number
       AND s.cs_item_sk = r.cr_item_sk
)
SELECT
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
    SUM(swr.cs_quantity) AS total_quantity_sold,
    SUM(swr.total_return_qty) AS total_quantity_returned,
    SUM(swr.cs_net_profit) AS total_net_profit,
    SUM(swr.total_return_loss) AS total_return_loss,
    SUM(swr.cs_net_profit) - SUM(swr.total_return_loss) AS net_profit_after_returns
FROM sales_with_returns swr
JOIN date_dim d ON swr.cs_sold_date_sk = d.d_date_sk
JOIN item i ON swr.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p ON swr.cs_promo_sk = p.p_promo_sk
WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
GROUP BY d.d_year, d.d_moy, i.i_category, COALESCE(p.p_promo_name, 'No Promotion')
ORDER BY net_profit_after_returns DESC
LIMIT 100
