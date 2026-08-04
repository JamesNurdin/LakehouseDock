WITH fact AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_refunded_cash,
        i.i_category_id,
        i.i_units,
        i.i_current_price,
        c.c_customer_id,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        sm.sm_type,
        sm.sm_contract,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
),
filtered_a AS (
    SELECT *
    FROM fact
    WHERE i_category_id IN (2, 4, 7)
      AND sm_type = 'EXPRESS'
      AND w_state = 'CA'
),
filtered_b AS (
    SELECT *
    FROM fact
    WHERE i_category_id IN (8, 9)
      AND sm_type = 'OVERNIGHT'
      AND w_state = 'CA'
),
unioned AS (
    SELECT * FROM filtered_a
    UNION DISTINCT
    SELECT * FROM filtered_b
)
SELECT
    u.w_city,
    u.w_warehouse_name,
    u.sm_type,
    u.cr_return_amount,
    RANK() OVER (PARTITION BY u.w_city ORDER BY u.cr_return_amount DESC) AS rk_city_return,
    ROW_NUMBER() OVER (ORDER BY u.cr_return_amount DESC) AS global_row_num,
    CASE amt.idx
        WHEN 1 THEN 'fee'
        WHEN 2 THEN 'refunded_cash'
        WHEN 3 THEN 'return_amount'
    END AS amount_type,
    amt.amount_value
FROM unioned u
CROSS JOIN UNNEST(ARRAY[u.cr_fee, u.cr_refunded_cash, u.cr_return_amount]) WITH ORDINALITY AS amt(amount_value, idx)
WHERE u.c_birth_year BETWEEN 1970 AND 1990
ORDER BY u.cr_return_amount DESC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
