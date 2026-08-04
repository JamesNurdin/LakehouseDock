WITH
  sr_data AS (
    SELECT
      sr.sr_returned_date_sk AS date_sk,
      sr.sr_return_amt,
      (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_date_sk = sr.sr_returned_date_sk
      ) AS total_inventory_on_return_date
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  cr_data AS (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  full_joined AS (
    SELECT
      COALESCE(sr.date_sk, cr.date_sk) AS date_sk,
      sr.sr_return_amt,
      cr.cr_return_amount,
      sr.total_inventory_on_return_date
    FROM sr_data sr
    FULL OUTER JOIN cr_data cr
      ON sr.date_sk = cr.date_sk
  ),
  set_a AS (
    SELECT date_sk
    FROM full_joined
    WHERE sr_return_amt > 0
  ),
  set_b AS (
    SELECT ws.ws_sold_date_sk AS date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_net_profit > 100
  ),
  intersected_dates AS (
    SELECT date_sk FROM set_a
    INTERSECT
    SELECT date_sk FROM set_b
  )
SELECT
  fj.date_sk,
  fj.sr_return_amt,
  fj.cr_return_amount,
  fj.total_inventory_on_return_date,
  (
    SELECT COUNT(*)
    FROM store_returns sr2
    WHERE sr2.sr_returned_date_sk = fj.date_sk
  ) AS store_return_count_for_date
FROM full_joined fj
WHERE fj.date_sk IN (SELECT date_sk FROM intersected_dates)
ORDER BY fj.date_sk
LIMIT 100
