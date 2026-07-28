WITH sales AS (
  SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_item_desc,
    td.t_hour,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_item_sk,
    ss.ss_store_sk,
    ss.ss_ticket_number,
    CONCAT(s.s_store_name, '-', i.i_item_id) AS store_item_key,
    p.p_promo_name
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE REGEXP_LIKE(i.i_item_desc, 'Premium')
    AND s.s_store_name LIKE '%Store%'
    AND (p.p_promo_name IS NULL OR REGEXP_LIKE(p.p_promo_name, 'Clearance'))
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = ss.ss_item_sk
          AND sr.sr_store_sk = ss.ss_store_sk
          AND sr.sr_ticket_number = ss.ss_ticket_number
    )
),
agg AS (
  SELECT
    store_item_key,
    s_store_name,
    i_item_id,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    MAX(t_hour) AS max_hour_sold
  FROM sales
  GROUP BY store_item_key, s_store_name, i_item_id
)
SELECT
  store_item_key,
  s_store_name,
  i_item_id,
  total_quantity,
  total_net_paid,
  total_net_profit,
  max_hour_sold,
  ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_net_paid DESC) AS sales_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
