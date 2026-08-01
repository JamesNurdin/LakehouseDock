WITH
  pref_young AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    INTERSECT
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_year > 1960
  ),
  old_nonpref AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_year < 1950
    EXCEPT
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'N'
  ),
  base AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      ca.ca_state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      d.d_date,
      d.d_year,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY i.inv_quantity_on_hand DESC) AS qty_rank,
      (
        SELECT COUNT(*)
        FROM inventory i2
        WHERE i2.inv_warehouse_sk = i.inv_warehouse_sk
      ) AS warehouse_item_count
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN customer c ON d.d_date_sk = c.c_first_sales_date_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.inv_quantity_on_hand > 0
      AND d.d_year = 2002
      AND ib.ib_lower_bound >= 20000
      AND hd.hd_vehicle_count >= 2
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_customer_sk IN (SELECT c_customer_sk FROM pref_young)
      AND c.c_customer_sk NOT IN (SELECT c_customer_sk FROM old_nonpref)
  )
SELECT
  b.c_customer_sk,
  b.c_first_name,
  b.c_last_name,
  b.ca_city,
  b.ca_state,
  b.ib_lower_bound,
  b.ib_upper_bound,
  b.inv_item_sk,
  b.inv_quantity_on_hand,
  b.d_date,
  b.qty_rank,
  b.warehouse_item_count
FROM base b
ORDER BY b.inv_quantity_on_hand DESC, b.c_customer_sk
OFFSET 10 ROWS
FETCH NEXT 100 ROWS ONLY
