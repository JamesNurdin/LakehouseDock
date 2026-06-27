WITH
sales_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_moy,
        i.i_category
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_moy,
        i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.total_sales_profit,
    coalesce(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - coalesce(r.total_return_loss, 0) AS net_profit
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.i_category = r.i_category
ORDER BY
    s.d_year,
    s.d_moy,
    s.i_category
