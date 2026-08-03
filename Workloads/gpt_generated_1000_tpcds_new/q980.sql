WITH filtered_returns AS (
  SELECT
    cr_returned_date_sk,
    cr_return_amount,
    cr_return_quantity,
    cr_store_credit,
    cr_reversed_charge,
    cr_call_center_sk,
    cr_order_number,
    cr_returning_addr_sk
  FROM catalog_returns
  TABLESAMPLE BERNOULLI (10)
  WHERE cr_return_amount > 50
    AND cr_return_quantity >= 1
    AND cr_store_credit < 100
    AND cr_reversed_charge BETWEEN 10 AND 500
    AND cr_returned_date_sk BETWEEN 2450000 AND 2455000
),
valid_call_center_keys AS (
  SELECT cr_call_center_sk
  FROM filtered_returns
  WHERE cr_return_amount > 200
),
other_call_center_keys AS (
  SELECT cr_call_center_sk
  FROM catalog_returns
  WHERE cr_store_credit > 500
),
call_center_keys_intersection AS (
  SELECT cr_call_center_sk
  FROM valid_call_center_keys
  INTERSECT
  SELECT cr_call_center_sk
  FROM other_call_center_keys
),
joined AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_state,
    cc.cc_gmt_offset,
    fr.cr_return_amount,
    fr.cr_return_quantity,
    fr.cr_order_number,
    fr.cr_returning_addr_sk
  FROM call_center cc
  JOIN filtered_returns fr
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_call_center_sk IN (SELECT cr_call_center_sk FROM call_center_keys_intersection)
    AND cc.cc_state NOT IN ('TX', 'CA')
    AND cc.cc_gmt_offset BETWEEN -5 AND 5
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
          AND cr2.cr_return_amount > 1000
      )
),
agg_per_center AS (
  SELECT
    cc_call_center_sk,
    cc_state,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    COUNT(DISTINCT cr_returning_addr_sk) AS distinct_returning_addresses,
    SUM(cr_return_quantity) AS total_quantity
  FROM joined
  GROUP BY cc_call_center_sk, cc_state
),
final AS (
  SELECT
    cc_state,
    AVG(total_return_amount) AS avg_total_return_amount,
    SUM(distinct_orders) AS sum_distinct_orders,
    AVG(distinct_returning_addresses) AS avg_distinct_addresses,
    SUM(total_quantity) AS sum_total_quantity
  FROM agg_per_center
  GROUP BY cc_state
  HAVING SUM(total_return_amount) > 1000
)
SELECT
  cc_state,
  avg_total_return_amount,
  sum_distinct_orders,
  avg_distinct_addresses,
  sum_total_quantity
FROM final
ORDER BY avg_total_return_amount DESC
LIMIT 20
