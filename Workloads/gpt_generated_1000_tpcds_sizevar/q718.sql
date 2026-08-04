WITH returns AS (
   SELECT
       i.i_item_id,
       i.i_item_desc,
       SUM(cr.cr_return_amount) AS amount,
       pl.promo_cnt,
       'return' AS src
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   CROSS JOIN LATERAL (
       SELECT COUNT(*) AS promo_cnt
       FROM promotion p
       WHERE p.p_item_sk = i.i_item_sk
   ) pl
   WHERE cr.cr_return_amount > (
       SELECT AVG(cr2.cr_return_amount)
       FROM catalog_returns cr2
   )
   GROUP BY i.i_item_id, i.i_item_desc, pl.promo_cnt
),
sales AS (
   SELECT
       i.i_item_id,
       i.i_item_desc,
       SUM(ws.ws_net_profit) AS amount,
       pl.promo_cnt,
       'sales' AS src
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   CROSS JOIN LATERAL (
       SELECT COUNT(*) AS promo_cnt
       FROM promotion p
       WHERE p.p_item_sk = i.i_item_sk
   ) pl
   WHERE EXISTS (
       SELECT 1
       FROM promotion p2
       WHERE p2.p_item_sk = i.i_item_sk
         AND p2.p_channel_event = 'N'
   )
   GROUP BY i.i_item_id, i.i_item_desc, pl.promo_cnt
)
SELECT
    ROW_NUMBER() OVER (ORDER BY u.amount DESC) AS rn,
    u.i_item_id,
    u.i_item_desc,
    u.amount,
    u.promo_cnt,
    u.src
FROM (
    SELECT * FROM returns
    UNION
    SELECT * FROM sales
) u
ORDER BY u.amount DESC
LIMIT 100
