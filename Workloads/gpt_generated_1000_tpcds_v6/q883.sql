WITH filtered_items AS (
    SELECT i_item_sk,
           i_brand,
           i_item_desc,
           i_product_name
    FROM   item
    WHERE  regexp_like(i_item_desc, '(?i)bike')
       AND i_brand LIKE 'A%'
)
SELECT s.s_store_id,
       concat(s.s_city, ', ', s.s_state)               AS store_location,
       fi.i_brand,
       regexp_extract(fi.i_item_desc, '(?i)(bike|bicycle)', 1) AS matched_term,
       substring(fi.i_product_name, 1, 10)                     AS product_prefix,
       sum(ss.ss_net_paid)                                     AS total_net_paid,
       count(*)                                                AS sales_cnt
FROM   filtered_items fi
JOIN   store_sales ss ON fi.i_item_sk = ss.ss_item_sk
JOIN   store s        ON ss.ss_store_sk = s.s_store_sk
JOIN   date_dim d     ON ss.ss_sold_date_sk = d.d_date_sk
WHERE  d.d_year = 2001
GROUP  BY s.s_store_id,
          s.s_city,
          s.s_state,
          fi.i_brand,
          regexp_extract(fi.i_item_desc, '(?i)(bike|bicycle)', 1),
          substring(fi.i_product_name, 1, 10)
ORDER  BY total_net_paid DESC
LIMIT  100
