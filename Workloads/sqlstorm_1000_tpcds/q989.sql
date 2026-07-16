SELECT
  d_year,
  s_state,
  i_category,
  p_promo_id,
  total_sales,
  total_returns,
  net_sales,
  RANK() OVER (PARTITION BY d_year ORDER BY net_sales DESC) AS sales_rank
FROM (
  SELECT
    d.d_year AS d_year,
    s.s_state AS s_state,
    i.i_category AS i_category,
    p.p_promo_id AS p_promo_id,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(CASE WHEN sr.sr_ticket_number IS NOT NULL THEN sr.sr_net_loss ELSE 0 END) AS total_returns,
    (SUM(ss.ss_net_paid) - SUM(CASE WHEN sr.sr_ticket_number IS NOT NULL THEN sr.sr_net_loss ELSE 0 END)) AS net_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
    AND s.s_state = 'CA'
    AND p.p_channel_tv = 'Y'
  GROUP BY d.d_year, s.s_state, i.i_category, p.p_promo_id
  HAVING SUM(ss.ss_net_paid) > 5000
) t
ORDER BY net_sales DESC
LIMIT 100
