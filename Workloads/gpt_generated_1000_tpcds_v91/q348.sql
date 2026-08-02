WITH unified_sales AS (
  SELECT
    ss.ss_item_sk AS item_sk,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_net_paid AS net_paid
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk IN (
    SELECT d_date_sk FROM date_dim WHERE d_year = 2002
  )
  UNION ALL
  SELECT
    ws.ws_item_sk AS item_sk,
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_net_paid AS net_paid
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk IN (
    SELECT d_date_sk FROM date_dim WHERE d_year = 2002
  )
)
SELECT
  i.i_item_id,
  i.i_item_desc,
  d.d_year,
  SUM(us.net_paid) AS total_sales,
  COUNT(DISTINCT us.customer_sk) AS distinct_customers,
  (
    SELECT COALESCE(SUM(inv.inv_quantity_on_hand), 0)
    FROM inventory inv
    JOIN date_dim inv_d ON inv.inv_date_sk = inv_d.d_date_sk
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv_d.d_year = d.d_year
  ) AS total_inventory_qty,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM promotion p
      JOIN date_dim p_d ON p.p_start_date_sk = p_d.d_date_sk
      WHERE p.p_item_sk = i.i_item_sk
        AND p_d.d_year = d.d_year
        AND p.p_channel_dmail = 'Y'
    ) THEN 'DM'
    ELSE 'No DM'
  END AS dm_promo_flag
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
GROUP BY i.i_item_id, i.i_item_desc, d.d_year, i.i_item_sk
ORDER BY total_sales DESC
LIMIT 100
