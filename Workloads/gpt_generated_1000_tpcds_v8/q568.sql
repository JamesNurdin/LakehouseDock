WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk,
      s.s_store_name AS store_name,
      i.i_item_sk,
      i.i_product_name AS product_name,
      SUM(ss.ss_quantity) AS total_qty,
      SUM(ss.ss_net_paid) AS total_net_paid,
      AVG(ss.ss_ext_discount_amt) AS avg_discount,
      CASE
        WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
        WHEN SUM(ss.ss_net_profit) BETWEEN 0 AND 10000 THEN 'Medium'
        ELSE 'Low'
      END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_company_id = 1
    GROUP BY ss.ss_store_sk, s.s_store_name, i.i_item_sk, i.i_product_name
  ),
  high_profit_items AS (
    SELECT i_item_sk
    FROM sales_agg
    WHERE profit_category = 'High'
  ),
  available_inventory AS (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
  ),
  sales_without_inventory AS (
    SELECT ss_item_sk
    FROM store_sales
    EXCEPT
    SELECT inv_item_sk FROM inventory
  ),
  top_reasons AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    ORDER BY r_reason_sk
    LIMIT 3
  )
SELECT
  sa.store_name,
  sa.product_name,
  sa.total_qty,
  sa.total_net_paid,
  sa.profit_category,
  CASE WHEN sa.i_item_sk IN (SELECT i_item_sk FROM high_profit_items) THEN 'Flagged' ELSE 'Normal' END AS flag_status,
  (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = sa.i_item_sk) AS return_count
FROM sales_agg sa
CROSS JOIN top_reasons tr
WHERE sa.ss_store_sk NOT IN (
        SELECT sr.sr_store_sk
        FROM store_returns sr
        WHERE sr.sr_reason_sk = (
                SELECT r_reason_sk FROM reason WHERE r_reason_desc = 'Customer not interested'
              )
      )
UNION
SELECT
  s.s_store_name AS store_name,
  i.i_product_name AS product_name,
  -sr.sr_return_quantity AS total_qty,
  -sr.sr_return_amt AS total_net_paid,
  'Return' AS profit_category,
  'Return' AS flag_status,
  0 AS return_count
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE sr.sr_return_quantity > 0
  AND sr.sr_item_sk NOT IN (SELECT i_item_sk FROM high_profit_items)
ORDER BY store_name, product_name
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
