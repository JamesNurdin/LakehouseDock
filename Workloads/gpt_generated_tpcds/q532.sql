WITH sales_agg AS (
    SELECT
        i.i_category,
        d_sales.d_year,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    GROUP BY i.i_category, d_sales.d_year
),
returns_agg AS (
    SELECT
        i.i_category,
        d_sales.d_year,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    GROUP BY i.i_category, d_sales.d_year
)
SELECT
    s.i_category,
    s.d_year AS sales_year,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_quantity_sold,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    ROW_NUMBER() OVER (
        PARTITION BY s.d_year
        ORDER BY s.total_sales_profit - COALESCE(r.total_return_loss, 0) DESC
    ) AS category_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
   AND s.d_year = r.d_year
WHERE s.d_year BETWEEN 2000 AND 2002
ORDER BY s.d_year, category_rank
