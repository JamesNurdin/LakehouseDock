WITH
  web_data AS (
    SELECT
      ws.ws_web_site_sk,
      ws.ws_sold_date_sk,
      t.t_sub_shift,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      p.p_promo_name,
      wsite.web_name
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND wsite.web_name LIKE 'W%'
  ),
  store_ret_data AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_returned_date_sk,
      t.t_sub_shift,
      sr.sr_net_loss,
      r.r_reason_desc,
      s.s_store_name
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)(size|warranty)')
  ),
  combined AS (
    SELECT
      'WEB' AS src,
      t_sub_shift,
      ws_net_profit AS amt,
      ws_ext_sales_price AS sales_price
    FROM web_data
    UNION ALL
    SELECT
      'STORE' AS src,
      t_sub_shift,
      -sr_net_loss AS amt,
      NULL AS sales_price
    FROM store_ret_data
  )
SELECT
  CONCAT(src, '_', t_sub_shift) AS src_shift,
  src,
  t_sub_shift,
  COUNT(*) AS txn_cnt,
  SUM(amt) AS total_amount,
  CASE
    WHEN SUM(amt) > 0 THEN 'POSITIVE'
    WHEN SUM(amt) < 0 THEN 'NEGATIVE'
    ELSE 'ZERO'
  END AS amount_sign,
  AVG(amt) AS avg_amount,
  (SELECT AVG(ws_net_profit) FROM web_sales) AS overall_avg_web_profit
FROM combined
WHERE (src = 'WEB' AND sales_price IS NOT NULL AND sales_price > 0)
   OR (src = 'STORE' AND amt <> 0)
GROUP BY src, t_sub_shift, CONCAT(src, '_', t_sub_shift)
ORDER BY total_amount DESC
LIMIT 100
