WITH sales_agg AS (
    SELECT
        i.i_category,
        d_ship.d_year,
        d_ship.d_moy AS month,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_ship.d_year, d_ship.d_moy
),
returns_agg AS (
    SELECT
        i.i_category,
        d_return.d_year,
        d_return.d_moy AS month,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_return.d_year, d_return.d_moy
)
SELECT
    s.i_category,
    s.d_year,
    s.month,
    s.total_sales_amount,
    s.total_profit,
    s.total_quantity_sold,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE WHEN s.total_quantity_sold > 0 THEN COALESCE(r.total_return_qty, 0) * 1.0 / s.total_quantity_sold ELSE 0 END AS return_rate
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
    AND s.d_year = r.d_year
    AND s.month = r.month
WHERE s.d_year = 2001
ORDER BY s.total_profit DESC
LIMIT 10
