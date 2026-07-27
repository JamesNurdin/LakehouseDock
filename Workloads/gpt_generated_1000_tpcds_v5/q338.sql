WITH returns_agg AS (
    SELECT
        cr_item_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_return_quantity > 0
    GROUP BY cr_item_sk, cr_ship_mode_sk
),
return_keys AS (
    SELECT DISTINCT
        cr_item_sk,
        cr_ship_mode_sk,
        cr_catalog_page_sk,
        cr_returning_customer_sk,
        cr_returning_addr_sk
    FROM catalog_returns
)
SELECT
    i.i_item_id,
    i.i_color,
    i.i_manager_id,
    sm.sm_carrier,
    cp.cp_department,
    c.c_customer_id,
    ca.ca_city,
    ra.total_return_amount,
    ra.total_return_qty,
    ra.return_cnt
FROM returns_agg ra
JOIN return_keys rk
    ON ra.cr_item_sk = rk.cr_item_sk
   AND ra.cr_ship_mode_sk = rk.cr_ship_mode_sk
JOIN item i
    ON ra.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp
    ON rk.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
    ON rk.cr_returning_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON rk.cr_returning_addr_sk = ca.ca_address_sk
WHERE i.i_color IN ('sandy', 'tan')
  AND i.i_manager_id = 64
  AND sm.sm_carrier = 'UPS'
  AND c.c_birth_year BETWEEN 1960 AND 1970
  AND cp.cp_department = 'Sports'
GROUP BY
    i.i_item_id,
    i.i_color,
    i.i_manager_id,
    sm.sm_carrier,
    cp.cp_department,
    c.c_customer_id,
    ca.ca_city,
    ra.total_return_amount,
    ra.total_return_qty,
    ra.return_cnt
ORDER BY ra.total_return_amount DESC
LIMIT 100
