WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_item_sk,
        cr.cr_refunded_addr_sk,
        i.i_item_desc,
        i.i_class,
        i.i_wholesale_cost,
        w.w_warehouse_name,
        r.r_reason_desc,
        ca.ca_city,
        ca.ca_street_name,
        sm.sm_code,
        sm.sm_contract,
        concat(ca.ca_street_number, ' ', ca.ca_street_name) AS full_street
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '(?i)infant|newborn')
      AND ca.ca_city LIKE '%York%'
      AND sm.sm_code = 'AIR'
      AND regexp_like(sm.sm_contract, '^A')
)
SELECT
    f.w_warehouse_name,
    f.r_reason_desc,
    COUNT(*) AS returns_cnt,
    SUM(f.cr_return_amount) AS total_return_amount,
    AVG(f.cr_return_quantity) AS avg_quantity,
    (
        SELECT AVG(i2.i_wholesale_cost)
        FROM item i2
        WHERE i2.i_class = f.i_class
    ) AS avg_wholesale_cost_for_class,
    substring(f.ca_city, 1, 3) AS city_prefix
FROM filtered f
WHERE EXISTS (
    SELECT 1
    FROM item i3
    WHERE i3.i_item_sk = f.cr_item_sk
      AND regexp_extract(i3.i_item_desc, '(?i)(infant|newborn)', 1) IS NOT NULL
)
GROUP BY
    f.w_warehouse_name,
    f.r_reason_desc,
    f.i_class,
    f.ca_city
HAVING SUM(f.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
