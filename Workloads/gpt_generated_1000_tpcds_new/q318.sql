WITH sales_items AS (
   SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_store_sk,
      ss.ss_addr_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      i.i_item_id,
      i.i_item_desc,
      i.i_category,
      i.i_brand,
      i.i_product_name
   FROM store_sales ss
   FULL OUTER JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
),
agg_sales AS (
   SELECT
      s.s_store_name,
      si.i_item_id,
      si.i_item_desc,
      si.i_category,
      si.i_brand,
      concat(s.s_store_name, ': ', si.i_item_id) AS store_item_key,
      substring(si.i_product_name, 1, 10) AS product_name_prefix,
      SUM(si.ss_net_paid) AS total_net_paid
   FROM sales_items si
   LEFT JOIN store s
      ON si.ss_store_sk = s.s_store_sk
   LEFT JOIN time_dim t
      ON si.ss_sold_time_sk = t.t_time_sk
   WHERE
      si.i_item_desc IS NOT NULL
      AND regexp_like(si.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND s.s_store_name IS NOT NULL
      AND s.s_store_name LIKE 'A%'
      AND t.t_hour IS NOT NULL
      AND t.t_hour BETWEEN 9 AND 17
   GROUP BY
      s.s_store_name,
      si.i_item_id,
      si.i_item_desc,
      si.i_category,
      si.i_brand,
      concat(s.s_store_name, ': ', si.i_item_id),
      substring(si.i_product_name, 1, 10)
)
SELECT
   a.s_store_name,
   a.i_item_id,
   a.i_item_desc,
   a.i_category,
   a.i_brand,
   a.store_item_key,
   a.product_name_prefix,
   a.total_net_paid,
   row_number() OVER (PARTITION BY a.s_store_name ORDER BY a.total_net_paid DESC) AS item_rank
FROM agg_sales a
ORDER BY a.total_net_paid DESC
LIMIT 100
