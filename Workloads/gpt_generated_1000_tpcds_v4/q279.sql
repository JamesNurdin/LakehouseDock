WITH filtered_returns AS (
   SELECT
       sr.sr_customer_sk,
       sr.sr_item_sk,
       sr.sr_reason_sk,
       sr.sr_net_loss,
       concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
       i.i_item_id,
       i.i_color,
       r.r_reason_desc
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE regexp_like(i.i_color, '^p')
     AND i.i_item_id LIKE 'ITEM_%'
),
unique_returns AS (
   SELECT DISTINCT
       sr_customer_sk,
       sr_item_sk,
       sr_reason_sk,
       sr_net_loss,
       customer_name,
       i_item_id,
       r_reason_desc
   FROM filtered_returns
)
SELECT
   customer_name,
   i_item_id,
   regexp_extract(r_reason_desc, '(\\w+)', 1) AS reason_first_word,
   COUNT(*) AS return_cnt,
   SUM(sr_net_loss) AS total_net_loss
FROM unique_returns
GROUP BY
   customer_name,
   i_item_id,
   regexp_extract(r_reason_desc, '(\\w+)', 1)
HAVING SUM(sr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
