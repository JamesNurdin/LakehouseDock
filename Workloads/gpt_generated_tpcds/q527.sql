WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_promo_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    p.p_promo_name,
    SUM(s.cs_net_paid_inc_tax) AS total_sales,
    COALESCE(SUM(r.cr_net_loss), 0) AS total_returns,
    SUM(s.cs_net_paid_inc_tax) - COALESCE(SUM(r.cr_net_loss), 0) AS net_revenue,
    COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT r.cr_order_number) AS distinct_returns
FROM sales s
JOIN date_dim d
  ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON s.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON s.cs_promo_sk = p.p_promo_sk
LEFT JOIN returns r
  ON s.cs_order_number = r.cr_order_number
  AND s.cs_item_sk = r.cr_item_sk
WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
GROUP BY d.d_year, d.d_moy, i.i_category, p.p_promo_name
ORDER BY d.d_year, d.d_moy, i.i_category, p.p_promo_name
