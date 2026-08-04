WITH
    ws_agg AS (
        SELECT
            ws_bill_customer_sk,
            COUNT(*) AS order_cnt,
            SUM(ws_net_paid) AS total_net_paid,
            AVG(ws_ext_discount_amt) AS avg_discount,
            MIN(ws_ship_date_sk) AS first_ship_sk,
            MAX(ws_ship_date_sk) AS last_ship_sk
        FROM web_sales
        WHERE ws_wholesale_cost > 30
          AND ws_wholesale_cost < 5000
          AND ws_ext_discount_amt BETWEEN 0 AND 200
          AND ws_ship_date_sk BETWEEN 2451400 AND 2452700
          AND ws_quantity >= 1
          AND ws_promo_sk IS NOT NULL
        GROUP BY ws_bill_customer_sk
    ),
    intersect_customers AS (
        SELECT ws_bill_customer_sk FROM web_sales WHERE ws_ext_discount_amt > 150
        INTERSECT
        SELECT ws_bill_customer_sk FROM web_sales WHERE ws_wholesale_cost < 100
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wa.order_cnt,
    wa.total_net_paid,
    wa.avg_discount,
    inc.income_key,
    inc.income_value
FROM intersect_customers ic
JOIN ws_agg wa ON ic.ws_bill_customer_sk = wa.ws_bill_customer_sk
JOIN customer c ON c.c_customer_sk = wa.ws_bill_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN LATERAL (
    SELECT map(ARRAY['lower', 'upper'], ARRAY[ib.ib_lower_bound, ib.ib_upper_bound]) AS income_map
) m
CROSS JOIN UNNEST(m.income_map) AS inc(income_key, income_value)
WHERE c.c_last_name = 'Breen'
  AND c.c_birth_year BETWEEN 1960 AND 1980
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_login LIKE '%shop%'
  AND c.c_email_address LIKE '%@example.com'
  AND hd.hd_vehicle_count >= 1
ORDER BY wa.total_net_paid DESC
LIMIT 100
