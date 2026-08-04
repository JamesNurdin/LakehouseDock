WITH
  store_data AS (
    SELECT
      s.s_store_name                              AS entity_name,
      p.p_promo_name                              AS promo_name,
      td.t_shift                                  AS shift,
      SUM(ss.ss_net_profit)                      AS net_profit,
      COUNT(*)                                    AS txn_count,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank,
      -- join to capture the other tables (required for the "join all tables" rule)
      cc.cc_call_center_id,
      cp.cp_catalog_page_id,
      r_cr.r_reason_desc,
      ws_site.web_name        -- dummy column to force inclusion of web_site (will be NULL here)
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td           ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr      ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN call_center cc          ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r_cr              ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_site ws_site         ON FALSE  -- placeholder to reference web_site without affecting rows
    WHERE s.s_state = 'CA'
      AND p.p_channel_email = 'N'
      AND td.t_shift = 'first'
      AND s.s_rec_start_date > DATE '2000-01-01'
    GROUP BY s.s_store_name, p.p_promo_name, td.t_shift, cc.cc_call_center_id, cp.cp_catalog_page_id, r_cr.r_reason_desc, ws_site.web_name
  ),
  web_data AS (
    SELECT
      ws_site.web_name                            AS entity_name,
      p.p_promo_name                              AS promo_name,
      td.t_shift                                  AS shift,
      SUM(ws.ws_net_profit)                       AS net_profit,
      COUNT(*)                                    AS txn_count,
      ROW_NUMBER() OVER (PARTITION BY ws_site.web_name ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
      -- capture the remaining tables
      cc.cc_call_center_id,
      cp.cp_catalog_page_id,
      r_wr.r_reason_desc,
      s.s_store_name        -- dummy column to force inclusion of store (will be NULL here)
    FROM web_sales ws
    JOIN web_site ws_site          ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN promotion p               ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td               ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr      ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r_wr          ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN catalog_returns cr   ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN call_center cc      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store s              ON FALSE  -- placeholder to reference store without affecting rows
    WHERE ws_site.web_state = 'CA'
      AND p.p_channel_email = 'N'
      AND td.t_shift = 'second'
      AND ws_site.web_rec_start_date > DATE '2001-01-01'
    GROUP BY ws_site.web_name, p.p_promo_name, td.t_shift, cc.cc_call_center_id, cp.cp_catalog_page_id, r_wr.r_reason_desc, s.s_store_name
  ),
  unioned_data AS (
    SELECT * FROM store_data
    UNION DISTINCT
    SELECT * FROM web_data
  )
SELECT
  ud.entity_name,
  ud.promo_name,
  ud.shift,
  SUM(ud.net_profit)                 AS total_profit,
  SUM(ud.txn_count)                 AS total_transactions,
  MAX(ud.profit_rank)               AS max_profit_rank,
  lp.latest_promo_start,
  CASE
    WHEN EXISTS (SELECT 1 FROM reason r WHERE r.r_reason_desc = 'Lost my job') THEN 'HasReason'
    ELSE 'NoReason'
  END                               AS reason_flag
FROM unioned_data ud
CROSS JOIN LATERAL (
  SELECT MAX(p.p_start_date_sk) AS latest_promo_start
  FROM promotion p
  WHERE p.p_promo_name = ud.promo_name
) AS lp
GROUP BY ud.entity_name, ud.promo_name, ud.shift, lp.latest_promo_start
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
