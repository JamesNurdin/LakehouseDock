WITH date_filtered AS (
    SELECT *
    FROM date_dim d
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 100 AND 200
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    ws.ws_net_profit               AS web_net_profit,
    ss.ss_net_profit               AS store_net_profit,
    cs.cs_net_profit               AS catalog_net_profit,
    cr.cr_net_loss,
    r.r_reason_desc,
    sm.sm_code,
    p.p_promo_name,
    w.w_warehouse_name,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    lf.discount_flag,
    g.grp
FROM date_filtered d
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
FULL OUTER JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN promotion p
  ON p.p_promo_sk = cs.cs_promo_sk
JOIN item i
  ON i.i_item_sk = cs.cs_item_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON r.r_reason_sk = cr.cr_reason_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) g
CROSS JOIN LATERAL (
    SELECT CASE WHEN p.p_discount_active = 'Y' THEN 'Discount' ELSE 'No Discount' END AS discount_flag
) lf
WHERE i.i_brand = 'BrandX'
  AND p.p_channel_catalog = 'N'
  AND sm.sm_code = 'AIR'
  AND w.w_state = 'CA'
  AND t.t_hour BETWEEN 8 AND 20
ORDER BY d.d_date DESC, profit_rank
LIMIT 100
