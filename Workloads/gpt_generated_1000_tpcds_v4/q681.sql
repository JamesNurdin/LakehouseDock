WITH base_returns AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_return_amt_inc_tax,
    cr.cr_fee,
    cr.cr_return_ship_cost,
    cr.cr_refunded_cash,
    cr.cr_reversed_charge,
    cr.cr_store_credit,
    cr.cr_net_loss,
    dd.d_date,
    dd.d_weekend,
    inv.inv_quantity_on_hand,
    it.i_item_sk,
    it.i_item_id,
    it.i_category,
    it.i_current_price,
    ws.web_site_id,
    ws.web_state
  FROM catalog_returns cr
  JOIN date_dim dd
    ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN inventory inv
    ON inv.inv_date_sk = dd.d_date_sk
  JOIN item it
    ON inv.inv_item_sk = it.i_item_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = dd.d_date_sk
  WHERE dd.d_weekend = 'N'
    AND inv.inv_quantity_on_hand > 0
    AND it.i_current_price BETWEEN 10 AND 100
    AND cr.cr_return_amount > 20
    AND ws.web_state = 'CA'
),
returns_split AS (
  SELECT
    *,
    CASE WHEN cr_return_quantity = 1 THEN 'Single' ELSE 'Multiple' END AS qty_group
  FROM base_returns
),
aggregated AS (
  SELECT
    i_category,
    qty_group,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(*) AS cnt_returns,
    RANK() OVER (PARTITION BY qty_group ORDER BY SUM(cr_return_amount) DESC) AS category_rank
  FROM returns_split
  GROUP BY i_category, qty_group
)
SELECT *
FROM (
  SELECT i_category, qty_group, total_return_amount, cnt_returns, category_rank
  FROM aggregated
  WHERE qty_group = 'Single'
  UNION ALL
  SELECT i_category, qty_group, total_return_amount, cnt_returns, category_rank
  FROM aggregated
  WHERE qty_group = 'Multiple'
) u
ORDER BY total_return_amount DESC
LIMIT 100
