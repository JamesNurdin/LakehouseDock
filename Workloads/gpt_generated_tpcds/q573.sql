WITH sales_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.category,
    s.total_sales,
    s.total_profit,
    s.total_discount,
    s.total_promo_cost,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amount, 0) / s.total_sales ELSE NULL END AS return_to_sales_ratio,
    s.total_profit - COALESCE(r.total_return_loss, 0) - s.total_promo_cost AS net_profit_after_returns_and_promo,
    CASE WHEN s.total_promo_cost > 0 THEN (s.total_profit - COALESCE(r.total_return_loss, 0) - s.total_promo_cost) / s.total_promo_cost ELSE NULL END AS roi_after_returns,
    s.order_cnt,
    COALESCE(r.return_order_cnt, 0) AS return_order_cnt
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.d_year = r.d_year
    AND s.d_moy = r.d_moy
    AND s.category = r.category
ORDER BY s.d_year, s.d_moy, s.category
