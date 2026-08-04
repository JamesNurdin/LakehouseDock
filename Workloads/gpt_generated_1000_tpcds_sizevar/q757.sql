WITH sr AS (
  SELECT *
  FROM store_returns
  WHERE sr_return_tax > 1.00
    AND sr_return_amt_inc_tax BETWEEN 10 AND 500
    AND sr_return_quantity >= 1
    AND sr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
          AND d_month_seq BETWEEN 1 AND 12
    )
    AND NOT EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = store_returns.sr_item_sk
          AND p.p_start_date_sk = store_returns.sr_returned_date_sk
    )
),
inv_sample AS (
  SELECT *
  FROM inventory TABLESAMPLE BERNOULLI (10)
),
promo_items AS (
  SELECT i.i_item_id
  FROM item i
  WHERE i.i_item_sk IN (
      SELECT p_item_sk
      FROM promotion
      WHERE p_discount_active = 'Y'
  )
  EXCEPT
  SELECT i2.i_item_id
  FROM item i2
  WHERE i2.i_item_sk NOT IN (
      SELECT p_item_sk
      FROM promotion
  )
)
SELECT
  d.d_year,
  d.d_quarter_name,
  i.i_brand,
  ca.ca_state,
  cd.cd_gender,
  ws.web_market_manager,
  COUNT(DISTINCT sr.sr_ticket_number) AS cnt_tickets,
  SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
  AVG(sr.sr_return_tax) AS avg_return_tax,
  MIN(sr.sr_return_quantity) AS min_quantity,
  MAX(sr.sr_return_quantity) AS max_quantity
FROM sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN inv_sample inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
                       OR ws.web_close_date_sk = d.d_date_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
                       AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE i.i_item_id IN (
    SELECT i_item_id FROM promo_items
)
  AND ws.web_mkt_id IN (1, 2, 3)
  AND ca.ca_country = 'United States'
GROUP BY
  d.d_year,
  d.d_quarter_name,
  i.i_brand,
  ca.ca_state,
  cd.cd_gender,
  ws.web_market_manager
ORDER BY total_return_amount DESC
LIMIT 100
