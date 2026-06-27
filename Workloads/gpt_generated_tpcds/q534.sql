WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        cd.cd_gender,
        sum(cs.cs_net_paid) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
    GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        cd.cd_gender,
        sum(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
    GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender
)
SELECT
    coalesce(s.d_year, r.d_year) AS year,
    coalesce(s.d_moy, r.d_moy) AS month,
    coalesce(s.i_category, r.i_category) AS category,
    coalesce(s.cd_gender, r.cd_gender) AS gender,
    coalesce(s.total_sales, 0) AS total_sales,
    coalesce(s.total_profit, 0) AS total_profit,
    coalesce(r.total_return_loss, 0) AS total_return_loss,
    coalesce(s.total_profit, 0) - coalesce(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_moy = r.d_moy
    AND s.i_category = r.i_category
    AND s.cd_gender = r.cd_gender
ORDER BY year, month, category, gender
