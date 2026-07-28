WITH sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    d.d_year,
    SUM(ss.ss_net_profit)               AS store_sales_profit,
    SUM(cs.cs_net_profit)               AS catalog_sales_profit,
    SUM(sr.sr_net_loss)                 AS store_returns_loss,
    SUM(cr.cr_net_loss)                 AS catalog_returns_loss,
    SUM(wr.wr_net_loss)                 AS web_returns_loss
  FROM date_dim d
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND s.s_state = 'CA'
    AND r.r_reason_desc LIKE '%damage%'
    AND ws.web_name = 'Main Web'
    AND p.p_discount_active = 'Y'
  GROUP BY s.s_store_sk, s.s_store_name, d.d_year
)
SELECT
  s_store_name,
  AVG(total_profit) AS avg_yearly_profit
FROM (
  SELECT
    s_store_name,
    d_year,
    (store_sales_profit + catalog_sales_profit - store_returns_loss - catalog_returns_loss - web_returns_loss) AS total_profit
  FROM sales_agg
) t
GROUP BY s_store_name
ORDER BY avg_yearly_profit DESC
LIMIT 100
