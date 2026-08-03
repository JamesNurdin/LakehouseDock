WITH store_sales_agg AS (
   SELECT ss.ss_sold_date_sk AS sold_date_sk,
          i.i_item_id,
          SUM(ss.ss_ext_sales_price) AS total_sales,
          ARRAY_AGG(DISTINCT p.p_promo_id) AS promo_ids
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE t.t_hour BETWEEN 9 AND 12
   GROUP BY ss.ss_sold_date_sk, i.i_item_id
),
store_sales_expanded AS (
   SELECT s.sold_date_sk,
          s.i_item_id,
          s.total_sales,
          pid AS promo_id
   FROM store_sales_agg s
   CROSS JOIN UNNEST(s.promo_ids) AS u(pid)
),
web_sales_agg AS (
   SELECT ws.ws_sold_date_sk AS sold_date_sk,
          i.i_item_id,
          SUM(ws.ws_ext_sales_price) AS total_sales,
          ARRAY_AGG(DISTINCT p.p_promo_id) AS promo_ids
   FROM web_sales ws
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE t.t_hour BETWEEN 9 AND 12
   GROUP BY ws.ws_sold_date_sk, i.i_item_id
),
web_sales_expanded AS (
   SELECT w.sold_date_sk,
          w.i_item_id,
          w.total_sales,
          pid AS promo_id
   FROM web_sales_agg w
   CROSS JOIN UNNEST(w.promo_ids) AS u(pid)
)
SELECT s.sold_date_sk,
       s.i_item_id,
       s.total_sales,
       s.promo_id
FROM store_sales_expanded s
UNION ALL
SELECT w.sold_date_sk,
       w.i_item_id,
       w.total_sales,
       w.promo_id
FROM web_sales_expanded w
ORDER BY sold_date_sk, total_sales DESC
LIMIT 100
