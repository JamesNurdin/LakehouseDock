WITH
  store_sales_agg AS (
    SELECT
      ss.ss_promo_sk AS promo_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ss.ss_net_profit) AS store_net_profit,
      COUNT(DISTINCT s.s_store_id) AS store_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY ss.ss_promo_sk
  ),
  catalog_sales_agg AS (
    SELECT
      cs.cs_promo_sk AS promo_sk,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
      SUM(cs.cs_net_paid) AS catalog_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_name = 'Main Call Center'
    GROUP BY cs.cs_promo_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_promo_sk AS promo_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      SUM(ws.ws_net_paid) AS web_net_paid
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date > DATE '1999-01-01'
    GROUP BY ws.ws_promo_sk
  ),
  returns_agg AS (
    SELECT
      ss.ss_promo_sk AS promo_sk,
      SUM(sr.sr_return_amt) AS returns_amount
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk
                       AND sr.sr_store_sk = ss.ss_store_sk
                       AND sr.sr_ticket_number = ss.ss_ticket_number
    GROUP BY ss.ss_promo_sk
  )
SELECT
  p.p_promo_id,
  p.p_promo_name,
  ss.store_sales_amount,
  cs.catalog_sales_amount,
  ws.web_sales_amount,
  COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) AS total_sales,
  COALESCE(r.returns_amount, 0) AS total_returns,
  COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) - COALESCE(r.returns_amount, 0) AS net_profit,
  CASE
    WHEN (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) - COALESCE(r.returns_amount, 0)) > 10000 THEN 'High'
    ELSE 'Low'
  END AS profit_category,
  ss.store_cnt,
  ROW_NUMBER() OVER (
    PARTITION BY CASE
                   WHEN (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) - COALESCE(r.returns_amount, 0)) > 10000 THEN 'High'
                   ELSE 'Low'
                 END
    ORDER BY (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) - COALESCE(r.returns_amount, 0)) DESC
  ) AS rank_in_category
FROM promotion p
LEFT JOIN store_sales_agg ss ON p.p_promo_sk = ss.promo_sk
LEFT JOIN catalog_sales_agg cs ON p.p_promo_sk = cs.promo_sk
LEFT JOIN web_sales_agg ws ON p.p_promo_sk = ws.promo_sk
LEFT JOIN returns_agg r ON p.p_promo_sk = r.promo_sk
WHERE p.p_channel_press = 'N'
  AND (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0)) > 5000
GROUP BY
  p.p_promo_id,
  p.p_promo_name,
  ss.store_sales_amount,
  cs.catalog_sales_amount,
  ws.web_sales_amount,
  r.returns_amount,
  ss.store_cnt,
  CASE
    WHEN (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) - COALESCE(r.returns_amount, 0)) > 10000 THEN 'High'
    ELSE 'Low'
  END
HAVING COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) > 10000
ORDER BY net_profit DESC
LIMIT 100
