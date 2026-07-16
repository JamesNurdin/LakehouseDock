WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year AS year,
        d.d_moy AS month,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_moy, cd.cd_gender
),
returns_agg AS (
    SELECT
        i.i_category AS category,
        dr.d_year AS year,
        dr.d_moy AS month,
        cd.cd_gender AS gender,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE dr.d_year = 2001
      AND r.r_reason_desc = 'Damaged'
    GROUP BY i.i_category, dr.d_year, dr.d_moy, cd.cd_gender
)
SELECT
    s.category,
    s.year,
    s.month,
    s.gender,
    s.total_sales,
    s.total_quantity_sold,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales_after_returns,
    CASE WHEN s.total_quantity_sold > 0
         THEN COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_quantity_sold
         ELSE 0 END AS return_rate,
    RANK() OVER (PARTITION BY s.year, s.month ORDER BY s.total_sales - COALESCE(r.total_return_loss, 0) DESC) AS category_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.category = r.category
   AND s.year = r.year
   AND s.month = r.month
   AND s.gender = r.gender
ORDER BY s.year, s.month, category_rank
LIMIT 50
