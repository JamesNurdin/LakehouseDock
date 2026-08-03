WITH item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        i.i_wholesale_cost,
        i.i_size,
        p.p_promo_id,
        p.p_cost,
        p.p_discount_active
    FROM item i
    FULL OUTER JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE (i.i_wholesale_cost BETWEEN 0.5 AND 5.0 OR i.i_wholesale_cost IS NULL)
      AND (i.i_size IN ('petite', 'economy', 'extra large') OR i.i_size IS NULL)
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ip.i_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_reversed_charge) AS avg_reversed_charge,
    MIN(sr.sr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(sr.sr_return_amt_inc_tax) AS max_return_inc_tax,
    RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(sr.sr_return_amt) DESC) AS category_return_rank,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper_bound,
    rev.potential_revenue
FROM store_returns sr
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item_promo ip
    ON sr.sr_item_sk = ip.i_item_sk
CROSS JOIN LATERAL (
    SELECT sr.sr_return_quantity * ip.i_current_price AS potential_revenue
) rev
WHERE sr.sr_return_quantity > 1
  AND sr.sr_return_amt > 10.00
  AND sr.sr_return_amt_inc_tax < 5000.00
  AND c.c_preferred_cust_flag = 'Y'
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_lower_bound >= 80000
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ip.i_category,
    rev.potential_revenue
ORDER BY total_return_amt DESC
LIMIT 100
