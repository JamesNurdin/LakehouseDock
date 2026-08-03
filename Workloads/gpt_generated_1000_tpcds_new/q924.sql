WITH
  sampled_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_product_name
    FROM   item
    TABLESAMPLE BERNOULLI (10)
  ),

  catalog_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           regexp_extract(i.i_product_name, '(\\w+)', 1)               AS first_word,
           CASE WHEN regexp_like(i.i_product_name, '\\bPremium\\b') THEN 'Premium' ELSE 'Standard' END AS product_type,
           SUM(cr.cr_return_amount)                                      AS total_return,
           COUNT(*)                                                       AS cnt_returns
    FROM   catalog_returns cr
    JOIN   sampled_items i ON cr.cr_item_sk = i.i_item_sk
    JOIN   household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE  hd.hd_vehicle_count > 0
    GROUP BY i.i_item_id, i.i_product_name
  ),

  web_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           regexp_extract(i.i_product_name, '(\\w+)', 1)               AS first_word,
           CASE WHEN regexp_like(i.i_product_name, '\\bPremium\\b') THEN 'Premium' ELSE 'Standard' END AS product_type,
           SUM(wr.wr_return_amt)                                         AS total_return,
           COUNT(*)                                                       AS cnt_returns
    FROM   web_returns wr
    JOIN   sampled_items i ON wr.wr_item_sk = i.i_item_sk
    JOIN   household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE  hd.hd_vehicle_count > 0
    GROUP BY i.i_item_id, i.i_product_name
  ),

  union_all AS (
    SELECT i_item_id,
           i_product_name,
           first_word,
           product_type,
           total_return,
           cnt_returns
    FROM   catalog_agg
    UNION DISTINCT
    SELECT i_item_id,
           i_product_name,
           first_word,
           product_type,
           total_return,
           cnt_returns
    FROM   web_agg
  ),

  low_potential_items AS (
    SELECT DISTINCT i.i_item_id
    FROM   catalog_returns cr
    JOIN   sampled_items i ON cr.cr_item_sk = i.i_item_sk
    JOIN   household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE  hd.hd_buy_potential = '0-500'
  ),

  excluded_ids AS (
    SELECT i_item_id FROM union_all
    EXCEPT
    SELECT i_item_id FROM low_potential_items
  ),

  final_set AS (
    SELECT u.*
    FROM   union_all u
    WHERE  u.i_item_id IN (SELECT i_item_id FROM excluded_ids)
  )
SELECT f.i_item_id,
       f.i_product_name,
       f.product_type,
       f.total_return,
       f.cnt_returns,
       lt.prod_type_len,
       row_number() OVER (PARTITION BY f.product_type ORDER BY f.total_return DESC) AS rank_by_return
FROM   final_set f
CROSS JOIN LATERAL (
  SELECT length(f.product_type) AS prod_type_len
) lt
WHERE  f.i_product_name LIKE '%a%'
ORDER BY f.product_type,
         rank_by_return
LIMIT 100
