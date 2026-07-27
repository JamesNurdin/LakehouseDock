WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d.d_year,
        d.d_month_seq,
        s.s_store_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND t.t_hour IN (6, 15)
      AND cd.cd_gender = 'F'
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 50000
      AND s.s_country = 'United States'
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    COUNT(DISTINCT cr_order_number) AS orders_returned,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_quantity,
    MIN(cr_net_loss) AS min_net_loss,
    MAX(cr_net_loss) AS max_net_loss
FROM filtered_returns
GROUP BY d_year, d_month_seq, s_store_name
ORDER BY total_return_amount DESC
LIMIT 50
