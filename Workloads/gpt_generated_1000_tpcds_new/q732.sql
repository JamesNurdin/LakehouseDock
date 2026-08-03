WITH sales_items AS (
   SELECT ss.ss_item_sk AS item_sk
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 9 AND 17
   GROUP BY ss.ss_item_sk
   HAVING SUM(ss.ss_net_paid) > 2000
),
returns_items AS (
   SELECT sr.sr_item_sk AS item_sk
   FROM store_returns sr
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 9 AND 17
   GROUP BY sr.sr_item_sk
   HAVING SUM(sr.sr_return_amt) > 800
),
common_items AS (
   SELECT item_sk FROM sales_items INTERSECT SELECT item_sk FROM returns_items
),
sales_agg AS (
   SELECT ss.ss_item_sk,
          i.i_category,
          i.i_product_name AS product_name,
          SUM(ss.ss_net_paid) AS total_net_paid,
          COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN common_items ci ON ss.ss_item_sk = ci.item_sk
   GROUP BY ss.ss_item_sk, i.i_category, i.i_product_name
   HAVING SUM(ss.ss_net_paid) > 1000
),
returns_agg AS (
   SELECT sr.sr_item_sk,
          i.i_category,
          i.i_product_name AS product_name,
          SUM(sr.sr_return_amt) AS total_return_amt,
          COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN common_items ci ON sr.sr_item_sk = ci.item_sk
   GROUP BY sr.sr_item_sk, i.i_category, i.i_product_name
   HAVING SUM(sr.sr_return_amt) > 500
),
full_join AS (
   SELECT COALESCE(sa.ss_item_sk, ra.sr_item_sk) AS item_sk,
          COALESCE(sa.total_net_paid, 0) AS total_net_paid,
          COALESCE(ra.total_return_amt, 0) AS total_return_amt,
          COALESCE(sa.product_name, ra.product_name) AS product_name
   FROM sales_agg sa
   FULL OUTER JOIN returns_agg ra ON sa.ss_item_sk = ra.sr_item_sk
)
SELECT fj.item_sk,
       fj.total_net_paid,
       fj.total_return_amt,
       fj.product_name,
       lt.shift_list
FROM full_join fj
LEFT JOIN LATERAL (
   SELECT array_agg(DISTINCT t.t_shift) AS shift_list
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE ss.ss_item_sk = fj.item_sk
) lt ON true
ORDER BY fj.total_net_paid DESC, fj.total_return_amt ASC
LIMIT 100
