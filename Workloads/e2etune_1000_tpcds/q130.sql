WITH returns_by_customer AS (
    SELECT
        cr.cr_refunded_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS num_returns,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 10
      AND cr.cr_return_ship_cost > 100
    GROUP BY cr.cr_refunded_customer_sk
)
SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(*) AS num_customers,
    SUM(rbc.total_return_amount) AS sum_return_amount,
    SUM(rbc.total_net_loss) AS sum_net_loss,
    AVG(rbc.avg_quantity) AS avg_quantity_per_customer
FROM returns_by_customer rbc
JOIN customer rc ON rbc.cr_refunded_customer_sk = rc.c_customer_sk
JOIN household_demographics hd ON rc.c_current_hdemo_sk = hd.hd_demo_sk
WHERE rc.c_birth_country = 'United States'
  AND hd.hd_vehicle_count >= 2
GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
ORDER BY sum_net_loss DESC
LIMIT 20
