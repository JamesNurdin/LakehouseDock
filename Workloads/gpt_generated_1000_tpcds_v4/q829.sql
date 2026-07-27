WITH returns_agg AS (
    SELECT
        cr_item_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_fee) AS total_fee,
        AVG(cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt,
        MIN(cr_return_ship_cost) AS min_ship_cost,
        MAX(cr_return_ship_cost) AS max_ship_cost
    FROM catalog_returns
    WHERE cr_return_ship_cost > 100
      AND cr_fee BETWEEN 20 AND 100
      AND cr_reversed_charge < 200
    GROUP BY cr_item_sk, cr_ship_mode_sk
)
SELECT
    i.i_brand,
    i.i_category,
    sm.sm_carrier,
    sm.sm_contract,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_tax) AS total_tax,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    ra.total_return_amount,
    ra.total_fee,
    ra.return_cnt,
    ra.avg_fee,
    ra.min_ship_cost,
    ra.max_ship_cost
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN returns_agg ra ON ra.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE i.i_current_price > 50
  AND i.i_brand = 'BRAND1'
  AND sm.sm_carrier IN ('UPS', 'DIAMOND')
  AND sm.sm_contract LIKE 'A5B%'
  AND ss.ss_ext_list_price > 1000
  AND ss.ss_ext_tax < 50
GROUP BY
    i.i_brand,
    i.i_category,
    sm.sm_carrier,
    sm.sm_contract,
    ra.total_return_amount,
    ra.total_fee,
    ra.return_cnt,
    ra.avg_fee,
    ra.min_ship_cost,
    ra.max_ship_cost
ORDER BY total_sales DESC
LIMIT 100
