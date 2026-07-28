WITH distinct_discount_promos AS (
  SELECT DISTINCT
    p.p_promo_id,
    p.p_promo_name,
    p.p_item_sk,
    p.p_start_date_sk,
    p.p_end_date_sk
  FROM promotion p
  WHERE regexp_like(p.p_promo_name, '(?i)discount')
    AND p.p_promo_id LIKE 'PR%'
),
promo_returns AS (
  SELECT
    dp.p_promo_id,
    dp.p_promo_name,
    dp.p_item_sk,
    dp.p_start_date_sk,
    dp.p_end_date_sk,
    d_start.d_date   AS start_date,
    d_end.d_date     AS end_date,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number)   AS web_return_cnt
  FROM distinct_discount_promos dp
  JOIN date_dim d_start ON dp.p_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end   ON dp.p_end_date_sk   = d_end.d_date_sk
  LEFT JOIN store_returns sr
    ON dp.p_item_sk = sr.sr_item_sk
   AND sr.sr_returned_date_sk BETWEEN dp.p_start_date_sk AND dp.p_end_date_sk
  LEFT JOIN web_returns wr
    ON dp.p_item_sk = wr.wr_item_sk
   AND wr.wr_returned_date_sk BETWEEN dp.p_start_date_sk AND dp.p_end_date_sk
  GROUP BY
    dp.p_promo_id,
    dp.p_promo_name,
    dp.p_item_sk,
    dp.p_start_date_sk,
    dp.p_end_date_sk,
    d_start.d_date,
    d_end.d_date
)
SELECT
  pr.p_promo_id,
  pr.p_promo_name,
  CONCAT('PROMO_', pr.p_promo_id) AS promo_key,
  pr.start_date,
  pr.end_date,
  pr.total_net_loss,
  CASE
    WHEN pr.total_net_loss > (SELECT AVG(total_net_loss) FROM promo_returns) THEN 'High'
    ELSE 'Low'
  END AS loss_severity,
  RANK() OVER (ORDER BY pr.total_net_loss DESC) AS loss_rank,
  pr.store_return_cnt,
  pr.web_return_cnt
FROM promo_returns pr
WHERE pr.total_net_loss IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = pr.p_item_sk
      AND inv.inv_quantity_on_hand > 0
  )
ORDER BY pr.total_net_loss DESC
LIMIT 100
