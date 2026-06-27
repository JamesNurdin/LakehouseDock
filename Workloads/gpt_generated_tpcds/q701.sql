WITH returns_agg AS (
    SELECT
        cr_order_number,
        cr_item_sk,
        SUM(cr_net_loss) AS total_return_loss
    FROM catalog_returns
    GROUP BY cr_order_number, cr_item_sk
)
SELECT
    date_trunc('month', d_sales.d_date) AS sales_month,
    i.i_category,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(COALESCE(r.total_return_loss, 0)) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns
FROM catalog_sales cs
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg r
  ON cs.cs_order_number = r.cr_order_number
  AND cs.cs_item_sk = r.cr_item_sk
WHERE d_sales.d_year = 2020
GROUP BY
    date_trunc('month', d_sales.d_date),
    i.i_category,
    p.p_promo_name
ORDER BY sales_month, total_sales DESC
