WITH base AS (
   SELECT i.i_item_sk,
          i.i_item_id,
          i.i_item_desc,
          i.i_current_price,
          p.p_promo_id,
          p.p_cost,
          p.p_channel_email,
          p.p_channel_tv,
          p.p_discount_active
   FROM tpcds.item i
   JOIN tpcds.promotion p
     ON p.p_item_sk = i.i_item_sk
   WHERE (p.p_channel_email = 'Y' OR p.p_channel_tv = 'Y')
     AND i.i_rec_start_date >= DATE '1999-01-01'
     AND i.i_rec_end_date <= DATE '2001-12-31'
),
union_set AS (
   SELECT i_item_id,
          i_item_desc,
          SUM(p_cost) AS total_promo_cost,
          COUNT(p_promo_id) AS promo_cnt
   FROM base
   WHERE p_channel_email = 'Y'
   GROUP BY i_item_id, i_item_desc
   HAVING COUNT(p_promo_id) > 1

   UNION

   SELECT i_item_id,
          i_item_desc,
          SUM(p_cost) AS total_promo_cost,
          COUNT(p_promo_id) AS promo_cnt
   FROM base
   WHERE p_channel_tv = 'Y'
   GROUP BY i_item_id, i_item_desc
   HAVING COUNT(p_promo_id) > 1
),
except_set AS (
   SELECT i.i_item_id
   FROM tpcds.promotion p
   JOIN tpcds.item i
     ON p.p_item_sk = i.i_item_sk
   WHERE p.p_discount_active = 'Y'
)
SELECT us.i_item_id,
       us.i_item_desc,
       us.total_promo_cost,
       us.promo_cnt,
       lc.total_all_promos
FROM union_set us
JOIN tpcds.item i2 ON i2.i_item_id = us.i_item_id
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS total_all_promos
    FROM tpcds.promotion p3
    WHERE p3.p_item_sk = i2.i_item_sk
) lc
EXCEPT
SELECT es.i_item_id,
       NULL,
       NULL,
       NULL,
       NULL
FROM except_set es
LIMIT 100
