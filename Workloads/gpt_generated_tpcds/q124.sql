WITH sales AS (
    SELECT
        d.d_year,
        month(d.d_date) AS month,
        i.i_category,
        sum(cs.cs_net_paid) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, month(d.d_date), i.i_category
),
returns AS (
    SELECT
        d.d_year,
        month(d.d_date) AS month,
        i.i_category,
        sum(cr.cr_return_amount) AS total_return_amount,
        sum(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, month(d.d_date), i.i_category
)
SELECT
    coalesce(s.d_year, r.d_year) AS year,
    coalesce(s.month, r.month) AS month,
    coalesce(s.i_category, r.i_category) AS category,
    coalesce(s.total_sales, 0) AS total_sales,
    coalesce(s.total_profit, 0) AS total_profit,
    coalesce(r.total_return_amount, 0) AS total_return_amount,
    coalesce(r.total_loss, 0) AS total_loss,
    (coalesce(s.total_profit, 0) - coalesce(r.total_loss, 0)) AS net_profit_after_returns
FROM sales s
FULL OUTER JOIN returns r
    ON s.d_year = r.d_year
    AND s.month = r.month
    AND s.i_category = r.i_category
ORDER BY year, month, category
