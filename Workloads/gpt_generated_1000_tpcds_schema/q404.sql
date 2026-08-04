WITH sampled_returns AS (
   SELECT *
   FROM catalog_returns TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
   SELECT
       cr.cr_warehouse_sk,
       cr.cr_item_sk,
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_store_credit,
       t.t_meal_time,
       t.t_time_id,
       w.w_warehouse_name,
       w.w_warehouse_sq_ft,
       i.i_brand,
       i.i_item_desc,
       i.i_units,
       i.i_current_price,
       split(i.i_item_desc, '\\s+') AS desc_words
   FROM sampled_returns cr
   JOIN time_dim t
     ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '(?i)(Pack|Box|Case)')
     AND i.i_units LIKE 'P%'
     AND w.w_warehouse_sq_ft > 500000
     AND i.i_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
)
SELECT
    wd.w_warehouse_name,
    wd.i_brand,
    COUNT(DISTINCT wd.cr_order_number) AS distinct_orders,
    SUM(wd.cr_return_amount) AS total_return_amount,
    AVG(wd.cr_return_quantity) AS avg_return_qty,
    CONCAT(wd.i_brand, ' - ', wd.w_warehouse_name) AS brand_warehouse,
    regexp_extract(wd.i_item_desc, '^([^\\s]+)', 1) AS first_word_desc,
    w.word
FROM joined_data wd
CROSS JOIN UNNEST(wd.desc_words) AS w(word)
GROUP BY
    wd.w_warehouse_name,
    wd.i_brand,
    CONCAT(wd.i_brand, ' - ', wd.w_warehouse_name),
    regexp_extract(wd.i_item_desc, '^([^\\s]+)', 1),
    w.word
HAVING SUM(wd.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
