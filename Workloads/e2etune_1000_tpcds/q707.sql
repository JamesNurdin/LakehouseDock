WITH cust_ship_inv AS (
    SELECT
        sm.sm_type,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        c.c_customer_sk,
        i.inv_quantity_on_hand
    FROM customer c
    JOIN income_band ib
      ON c.c_current_cdemo_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
      ON c.c_current_hdemo_sk = sm.sm_ship_mode_sk
    LEFT JOIN inventory i
      ON i.inv_warehouse_sk = sm.sm_ship_mode_sk
    WHERE c.c_birth_country = 'IRELAND'
      AND c.c_birth_year BETWEEN 1950 AND 1970
),
agg AS (
    SELECT
        sm_type,
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        COUNT(DISTINCT c_customer_sk) AS cust_cnt,
        COALESCE(SUM(inv_quantity_on_hand), 0) AS total_inventory
    FROM cust_ship_inv
    GROUP BY sm_type, ib_income_band_sk, ib_lower_bound, ib_upper_bound
    HAVING COUNT(DISTINCT c_customer_sk) > 5
)
SELECT
    sm_type,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    cust_cnt,
    total_inventory,
    ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY cust_cnt DESC) AS cust_rank
FROM agg
ORDER BY sm_type, cust_cnt DESC
LIMIT 20
