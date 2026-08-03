WITH
store_agg AS (
  SELECT
    d.d_date,
    ca.ca_state,
    i.i_item_id,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_on_hand
  FROM store_returns sr
  FULL OUTER JOIN inventory inv
    ON sr.sr_item_sk = inv.inv_item_sk
   AND sr.sr_returned_date_sk = inv.inv_date_sk
  LEFT JOIN date_dim d
    ON COALESCE(sr.sr_returned_date_sk, inv.inv_date_sk) = d.d_date_sk
  LEFT JOIN item i
    ON COALESCE(sr.sr_item_sk, inv.inv_item_sk) = i.i_item_sk
  LEFT JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_date, ca.ca_state, i.i_item_id
  HAVING SUM(COALESCE(sr.sr_return_amt, 0)) > (
        SELECT MAX(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk = 2450836
    )
),
store_expanded AS (
  SELECT
    d_date,
    ca_state,
    i_item_id,
    total_return_qty,
    total_return_amt,
    total_on_hand,
    state_variant
  FROM store_agg
  CROSS JOIN UNNEST(array[ca_state, 'STORE']) AS t(state_variant)
),
catalog_agg AS (
  SELECT
    d.d_date,
    ca.ca_state,
    i.i_item_id,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amt
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_date, ca.ca_state, i.i_item_id
),
catalog_expanded AS (
  SELECT
    d_date,
    ca_state,
    i_item_id,
    total_return_qty,
    total_return_amt,
    NULL AS total_on_hand,
    state_variant
  FROM catalog_agg
  CROSS JOIN UNNEST(array[ca_state, 'CATALOG']) AS t(state_variant)
)
SELECT
  d_date,
  ca_state,
  i_item_id,
  total_return_qty,
  total_return_amt,
  total_on_hand,
  state_variant
FROM store_expanded
UNION
SELECT
  d_date,
  ca_state,
  i_item_id,
  total_return_qty,
  total_return_amt,
  total_on_hand,
  state_variant
FROM catalog_expanded
ORDER BY d_date, i_item_id, state_variant
LIMIT 100
