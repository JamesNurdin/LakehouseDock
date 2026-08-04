WITH
  base AS (
    SELECT
      dd.d_year,
      dd.d_month_seq,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_ext_sales_price AS store_sales,
      ss.ss_net_profit AS store_profit,
      p.p_channel_dmail,
      sr.sr_reason_sk,
      r.r_reason_desc AS store_return_reason,
      inv.inv_quantity_on_hand,
      ss.ss_ticket_number,
      ss.ss_promo_sk,
      ss.ss_sold_date_sk,
      -- correlated scalar subquery: count of returns for the same store
      (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_store_sk = ss.ss_store_sk) AS store_return_count
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                               AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = dd.d_date_sk
  ),
  web_data AS (
    SELECT
      dd2.d_year AS web_year,
      ws.ws_order_number,
      ws.ws_ext_sales_price AS web_sales,
      ws.ws_net_profit AS web_profit,
      p2.p_channel_email,
      sm.sm_type AS ship_type,
      wr.wr_reason_sk,
      r2.r_reason_desc AS web_return_reason,
      wp.wp_type AS page_type,
      ws.ws_web_site_sk,
      ws.ws_web_page_sk,
      ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN date_dim dd2 ON ws.ws_sold_date_sk = dd2.d_date_sk
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  ),
  combined AS (
    SELECT
      COALESCE(b.d_year, w.web_year)                                   AS year,
      COALESCE(b.ss_item_sk, w.ws_order_number)                        AS key_id,
      b.store_sales,
      w.web_sales,
      b.store_profit,
      w.web_profit,
      CASE WHEN b.p_channel_dmail = 'Y' THEN 1 ELSE 0 END            AS dmail_flag,
      CASE WHEN w.p_channel_email = 'Y' THEN 1 ELSE 0 END            AS email_flag,
      b.inv_quantity_on_hand,
      w.ship_type,
      b.store_return_reason,
      w.web_return_reason,
      b.store_return_count
    FROM base b
    FULL OUTER JOIN web_data w
      ON b.d_year = w.web_year
     AND b.ss_item_sk = w.ws_order_number
  )
SELECT *
FROM (
  SELECT
    year,
    SUM(COALESCE(store_sales, 0))                          AS total_store_sales,
    SUM(COALESCE(web_sales, 0))                            AS total_web_sales,
    SUM(COALESCE(store_profit, 0)) - SUM(COALESCE(web_profit, 0)) AS profit_diff,
    SUM(inv_quantity_on_hand)                              AS total_inventory,
    SUM(CASE WHEN dmail_flag = 1 THEN store_sales ELSE 0 END) AS dmail_sales,
    AVG(COALESCE(store_sales, 0) + COALESCE(web_sales, 0)) AS avg_total_sales
  FROM combined
  WHERE year BETWEEN 1998 AND 2002                                     -- predicate 1
    AND (dmail_flag = 1 OR email_flag = 1)                               -- predicate 2
    AND inv_quantity_on_hand > 500                                      -- predicate 3
    AND ship_type IS NOT NULL                                            -- predicate 4
    AND (store_return_reason IS NOT NULL OR web_return_reason IS NOT NULL) -- predicate 5
  GROUP BY year
  HAVING SUM(COALESCE(store_sales, 0)) > 10000

  EXCEPT

  SELECT
    year,
    SUM(COALESCE(store_sales, 0))                          AS total_store_sales,
    SUM(COALESCE(web_sales, 0))                            AS total_web_sales,
    SUM(COALESCE(store_profit, 0)) - SUM(COALESCE(web_profit, 0)) AS profit_diff,
    SUM(inv_quantity_on_hand)                              AS total_inventory,
    SUM(CASE WHEN dmail_flag = 1 THEN store_sales ELSE 0 END) AS dmail_sales,
    AVG(COALESCE(store_sales, 0) + COALESCE(web_sales, 0)) AS avg_total_sales
  FROM combined
  WHERE year = 2000
  GROUP BY year
) final_result
ORDER BY profit_diff DESC
LIMIT 100
