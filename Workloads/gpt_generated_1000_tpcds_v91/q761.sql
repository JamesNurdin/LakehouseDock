WITH
sampled_sales AS (
  SELECT *
  FROM web_sales
  TABLESAMPLE BERNOULLI (10)
),
promo_filtered AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_id,
    p.p_promo_name,
    regexp_extract(p.p_promo_id, '\\d+', 0) AS promo_id_numeric,
    p.p_channel_details,
    concat('Promo_', p.p_promo_id) AS promo_label,
    substring(p.p_promo_name FROM 1 FOR 15) AS promo_name_prefix
  FROM promotion p
  WHERE regexp_like(p.p_promo_name, '(?i)Discount|Sale')
    AND p.p_channel_details LIKE '%email%'
)
SELECT
  pf.p_promo_id,
  pf.promo_label,
  pf.promo_name_prefix,
  COUNT(DISTINCT s.ws_order_number) AS order_cnt,
  SUM(s.ws_net_paid) AS total_net_paid,
  SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
  COUNT(DISTINCT wr.wr_order_number) AS return_order_cnt,
  SUM(CASE WHEN cd.cd_gender = 'M' THEN COALESCE(wr.wr_net_loss, 0) ELSE 0 END) AS male_return_net_loss,
  concat(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital
FROM sampled_sales s
JOIN promo_filtered pf
  ON s.ws_promo_sk = pf.p_promo_sk
LEFT JOIN web_returns wr
  ON s.ws_item_sk = wr.wr_item_sk
  AND s.ws_order_number = wr.wr_order_number
LEFT JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE s.ws_quantity > 0
GROUP BY
  pf.p_promo_id,
  pf.promo_label,
  pf.promo_name_prefix,
  concat(cd.cd_gender, '-', cd.cd_marital_status)
ORDER BY total_return_net_loss DESC
LIMIT 100
