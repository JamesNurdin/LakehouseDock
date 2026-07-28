WITH
  ss_agg AS (
    SELECT
      ss_store_sk,
      ss_sold_date_sk,
      ss_promo_sk,
      SUM(ss_net_paid) AS store_net_paid,
      SUM(ss_net_profit) AS store_profit
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_promo_sk
  ),
  ws_agg AS (
    SELECT
      ws_web_site_sk,
      ws_sold_date_sk,
      ws_ship_date_sk,
      ws_ship_mode_sk,
      SUM(ws_net_paid) AS web_net_paid,
      SUM(ws_net_profit) AS web_profit
    FROM web_sales
    GROUP BY ws_web_site_sk, ws_sold_date_sk, ws_ship_date_sk, ws_ship_mode_sk
  ),
  wr_agg AS (
    SELECT
      wr_returned_date_sk,
      SUM(wr_return_amt) AS return_amt
    FROM web_returns
    GROUP BY wr_returned_date_sk
  )
SELECT
  s.s_store_name,
  ws_site.web_name,
  d_sold.d_year,
  d_sold.d_month_seq,
  SUM(ss.store_net_paid)               AS total_store_sales,
  SUM(wa.web_net_paid)                 AS total_web_sales,
  SUM(wr.return_amt)                  AS total_returns,
  SUM(p_sales.p_cost)                  AS total_promo_cost
FROM ss_agg ss
JOIN date_dim d_sold   ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s           ON ss.ss_store_sk     = s.s_store_sk
JOIN promotion p_sales ON ss.ss_promo_sk    = p_sales.p_promo_sk
JOIN ws_agg wa        ON wa.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site ws_site ON wa.ws_web_site_sk  = ws_site.web_site_sk
JOIN ship_mode sm     ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_ship  ON wa.ws_ship_date_sk = d_ship.d_date_sk
JOIN wr_agg wr        ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE EXISTS (
        SELECT 1
        FROM promotion p_email
        WHERE p_email.p_promo_sk = ss.ss_promo_sk
          AND p_email.p_channel_email = 'Y'
      )
GROUP BY GROUPING SETS (
        (s.s_store_name, ws_site.web_name, d_sold.d_year, d_sold.d_month_seq),
        (s.s_store_name, ws_site.web_name, d_sold.d_year),
        (s.s_store_name, ws_site.web_name),
        (s.s_store_name),
        ()
      )
ORDER BY total_store_sales DESC
LIMIT 100
