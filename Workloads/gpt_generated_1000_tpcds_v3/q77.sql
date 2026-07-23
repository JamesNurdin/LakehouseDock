WITH sales AS (
   SELECT
       d.d_date AS transaction_date,
       i.i_item_id,
       'sale' AS transaction_type,
       ss.ss_quantity AS quantity,
       ss.ss_net_paid AS amount,
       p.p_promo_name AS promo_name,
       s.s_store_name AS store_name
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2000
     AND p.p_discount_active = 'Y'
),
returns AS (
   SELECT
       d.d_date AS transaction_date,
       i.i_item_id,
       'return' AS transaction_type,
       cr.cr_return_quantity AS quantity,
       cr.cr_return_amount AS amount,
       p.p_promo_name AS promo_name,
       CAST(NULL AS varchar) AS store_name
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND p.p_discount_active = 'Y'
)
SELECT
    transaction_date,
    i_item_id,
    transaction_type,
    quantity,
    amount,
    promo_name,
    store_name
FROM (
    SELECT transaction_date, i_item_id, transaction_type, quantity, amount, promo_name, store_name FROM sales
    UNION ALL
    SELECT transaction_date, i_item_id, transaction_type, quantity, amount, promo_name, store_name FROM returns
) combined
ORDER BY transaction_date, transaction_type, amount DESC
LIMIT 100
