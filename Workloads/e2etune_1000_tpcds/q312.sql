WITH monthly_ship_promo AS (
  SELECT
    d.d_year,
    d.d_moy AS month,
    sm.sm_type AS ship_mode,
    p.p_promo_name AS promotion,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS unique_customers
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p
    ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  WHERE p.p_discount_active = 'Y'
    AND d.d_year = 2022
  GROUP BY
    d.d_year,
    d.d_moy,
    sm.sm_type,
    p.p_promo_name
)
SELECT
  *,
  ROW_NUMBER() OVER (PARTITION BY d_year, month, ship_mode ORDER BY total_net_loss DESC) AS net_loss_rank
FROM monthly_ship_promo
ORDER BY total_net_loss DESC
LIMIT 100
