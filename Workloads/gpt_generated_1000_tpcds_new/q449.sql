WITH catalog_part AS (
  SELECT
    d.d_date AS sale_date,
    i.i_item_id,
    c.c_customer_id,
    cs.cs_order_number AS order_number,
    cs.cs_net_profit AS net_profit,
    CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    pl.promo_cnt,
    r.r_reason_desc
  FROM catalog_sales cs
  JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
  JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
  JOIN item i                   ON cs.cs_item_sk        = i.i_item_sk
  JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p              ON cs.cs_promo_sk       = p.p_promo_sk
  JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm             ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
  JOIN warehouse w              ON cs.cs_warehouse_sk   = w.w_warehouse_sk
  FULL OUTER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  FULL OUTER JOIN reason r          ON cr.cr_reason_sk    = r.r_reason_sk
  LEFT JOIN web_site ws               ON ws.web_open_date_sk = d.d_date_sk
  LEFT JOIN web_page wp               ON wp.wp_creation_date_sk = d.d_date_sk
  CROSS JOIN LATERAL (
    SELECT count(*) AS promo_cnt
    FROM promotion p_l
    WHERE p_l.p_item_sk = cs.cs_item_sk
  ) pl
  WHERE d.d_year = 2001
    AND i.i_color = 'Blue'
    AND cd.cd_gender = 'M'
    AND p.p_channel_radio = 'N'
),
store_part AS (
  SELECT
    d.d_date AS sale_date,
    i.i_item_id,
    c.c_customer_id,
    ss.ss_ticket_number AS order_number,
    ss.ss_net_profit AS net_profit,
    CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    pl.promo_cnt,
    r.r_reason_desc
  FROM store_sales ss
  JOIN date_dim d               ON ss.ss_sold_date_sk   = d.d_date_sk
  JOIN time_dim t               ON ss.ss_sold_time_sk   = t.t_time_sk
  JOIN item i                   ON ss.ss_item_sk        = i.i_item_sk
  JOIN customer c               ON ss.ss_customer_sk    = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk       = cd.cd_demo_sk
  JOIN promotion p              ON ss.ss_promo_sk       = p.p_promo_sk
  LEFT JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r            ON sr.sr_reason_sk      = r.r_reason_sk
  LEFT JOIN web_site ws         ON ws.web_open_date_sk = d.d_date_sk
  LEFT JOIN web_page wp         ON wp.wp_creation_date_sk = d.d_date_sk
  CROSS JOIN LATERAL (
    SELECT count(*) AS promo_cnt
    FROM promotion p_l
    WHERE p_l.p_item_sk = ss.ss_item_sk
  ) pl
  WHERE d.d_year = 2001
    AND i.i_color = 'Blue'
    AND cd.cd_gender = 'M'
    AND p.p_channel_radio = 'N'
)
SELECT
  sale_date,
  i_item_id,
  c_customer_id,
  COUNT(DISTINCT order_number)               AS orders,
  SUM(net_profit)                            AS total_profit,
  AVG(promo_cnt)                             AS avg_promo_per_item,
  COUNT(CASE WHEN profit_flag = 'POS' THEN 1 END) AS positive_profit_count,
  MIN(r_reason_desc)                         AS sample_reason
FROM (
  SELECT * FROM catalog_part
  UNION DISTINCT
  SELECT * FROM store_part
) u
GROUP BY sale_date, i_item_id, c_customer_id
ORDER BY total_profit DESC
LIMIT 100
