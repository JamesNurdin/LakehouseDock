WITH scalar_max_income AS (
    SELECT MAX(ib2.ib_upper_bound) AS max_ub
    FROM income_band ib2
)
SELECT
    d.d_year,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_id,
    t_sr.t_hour,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(sr.sr_return_amt) AS total_store_return,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    (SELECT max_ub FROM scalar_max_income) AS max_income_upper_bound
FROM date_dim d
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t_cr
  ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
WHERE d.d_year = 2001
  AND ib.ib_lower_bound >= 50000
  AND i.inv_warehouse_sk IN (1, 4, 14)
  AND p.p_purpose = 'Unknown'
  AND t_sr.t_hour BETWEEN 9 AND 17
  AND cr.cr_return_amount > 100.00
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = sr.sr_customer_sk
          AND cr2.cr_return_amount > 200.00
    )
GROUP BY
    d.d_year,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_id,
    t_sr.t_hour
ORDER BY d.d_year DESC, total_store_return DESC
LIMIT 100
