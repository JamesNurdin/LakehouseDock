WITH ss_agg AS (
  SELECT
    d.d_year                     AS year,
    s.s_store_name               AS location_name,
    p.p_promo_name               AS promo_name,
    SUM(ss.ss_net_paid)         AS total_paid,
    SUM(ss.ss_net_profit)       AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders_cnt
  FROM store_sales ss
  JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s              ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN inventory inv       ON d.d_date_sk = inv.inv_date_sk
  JOIN warehouse w         ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
                           AND sr.sr_item_sk = ss.ss_item_sk
  JOIN reason r            ON sr.sr_reason_sk = r.r_reason_sk
  GROUP BY d.d_year, s.s_store_name, p.p_promo_name
),
cs_agg AS (
  SELECT
    d_sold.d_year                AS year,
    cc.cc_name                   AS location_name,
    p.p_promo_name               AS promo_name,
    SUM(cs.cs_net_paid)         AS total_paid,
    SUM(cs.cs_net_profit)       AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
  FROM catalog_sales cs
  JOIN date_dim d_sold          ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship          ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w             ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p             ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  GROUP BY d_sold.d_year, cc.cc_name, p.p_promo_name
),
wr_agg AS (
  SELECT
    d.d_year                     AS year,
    ws.web_name                  AS location_name,
    CAST(NULL AS varchar)        AS promo_name,
    -SUM(wr.wr_return_amt)       AS total_paid,
    SUM(wr.wr_net_loss)          AS total_profit,
    COUNT(DISTINCT wr.wr_order_number) AS orders_cnt
  FROM web_returns wr
  JOIN date_dim d               ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r                 ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp              ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws              ON d.d_date_sk = ws.web_open_date_sk
  JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
  GROUP BY d.d_year, ws.web_name
)
SELECT
  combined.year,
  combined.location_name,
  combined.promo_name,
  combined.total_paid,
  combined.total_profit,
  combined.orders_cnt,
  pc.active_promo_cnt
FROM (
  SELECT * FROM ss_agg
  UNION ALL
  SELECT * FROM cs_agg
  UNION ALL
  SELECT * FROM wr_agg
) combined
CROSS JOIN (
  SELECT COUNT(DISTINCT p.p_promo_sk) AS active_promo_cnt
  FROM promotion p
  WHERE p.p_discount_active = 'Y'
) pc
ORDER BY combined.year DESC, combined.total_paid DESC
LIMIT 100
