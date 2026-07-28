WITH filtered_returns AS (
        SELECT *
        FROM catalog_returns
        WHERE cr_return_amount > 500
          AND cr_return_ship_cost < 200
          AND cr_return_quantity BETWEEN 1 AND 10
          AND cr_return_tax > 0
          AND cr_return_tax < 100
    ),
    filtered_cc AS (
        SELECT *
        FROM call_center
        WHERE cc_state = 'CA'
          AND cc_gmt_offset BETWEEN -7.00 AND -5.00
          AND cc_mkt_class LIKE '%Major%'
          AND cc_employees > 100
          AND cc_sq_ft >= 2000
    )
SELECT
    fc.cc_call_center_id,
    fc.cc_state,
    fc.cc_market_manager,
    COUNT(fr.cr_order_number) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_ship_cost) AS avg_ship_cost,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_cc fc
JOIN filtered_returns fr
  ON fr.cr_call_center_sk = fc.cc_call_center_sk
GROUP BY fc.cc_call_center_id, fc.cc_state, fc.cc_market_manager
HAVING SUM(fr.cr_return_amount) > 10000
   AND COUNT(fr.cr_order_number) > 50
ORDER BY total_return_amount DESC
LIMIT 100
