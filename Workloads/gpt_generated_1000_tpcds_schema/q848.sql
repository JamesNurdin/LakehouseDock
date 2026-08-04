WITH sampled_items AS (
   SELECT
       i_item_sk,
       i_item_id,
       i_rec_end_date,
       i_manufact_id,
       i_color,
       i_product_name
   FROM item TABLESAMPLE BERNOULLI (10)
   WHERE i_rec_end_date > DATE '2000-01-01'
     AND i_manufact_id IN (625, 350)
     AND i_color IN ('purple', 'rosy', 'yellow')
),
joined_promotions AS (
   SELECT DISTINCT
       i.i_item_sk,
       i.i_item_id,
       i.i_product_name,
       p.p_promo_name,
       p.p_channel_tv,
       p.p_channel_press
   FROM sampled_items i
   FULL OUTER JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
   WHERE p.p_channel_tv = 'N'
     AND p.p_channel_press = 'N'
),
returns_with_customers AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_reversed_charge,
       c.c_customer_sk,
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_salutation,
       i.i_item_sk
   FROM web_returns wr
   JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
   JOIN sampled_items i
        ON wr.wr_item_sk = i.i_item_sk
   WHERE c.c_salutation = 'Mr.'
     AND wr.wr_reversed_charge > 100
)
SELECT
    rw.c_customer_id,
    rw.c_first_name,
    rw.c_last_name,
    rw.c_salutation,
    i.i_item_id,
    i.i_product_name,
    jp.p_promo_name,
    rw.wr_return_quantity,
    rw.wr_return_amt,
    ROW_NUMBER() OVER (ORDER BY rw.wr_returned_date_sk DESC) AS global_row_num,
    ROW_NUMBER() OVER (PARTITION BY rw.c_customer_sk ORDER BY rw.wr_returned_date_sk DESC) AS cust_return_rank
FROM returns_with_customers rw
LEFT JOIN joined_promotions jp
     ON jp.i_item_sk = rw.i_item_sk
LEFT JOIN sampled_items i
     ON i.i_item_sk = rw.i_item_sk
WHERE i.i_rec_end_date > DATE '2000-01-01'
ORDER BY global_row_num
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
