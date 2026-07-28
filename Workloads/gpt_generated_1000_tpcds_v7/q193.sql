WITH base AS (
  SELECT
    cp.cp_catalog_page_number,
    cp.cp_department,
    p.p_promo_id,
    w.w_state,
    s.s_store_name,
    r.r_reason_desc,
    cs.cs_net_profit,
    cr.cr_net_loss,
    sr.sr_net_loss,
    wr.wr_net_loss,
    i.inv_quantity_on_hand,
    cs.cs_sold_date_sk,
    cs.cs_order_number
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN store_returns sr
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
   AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   AND cs.cs_ship_cdemo_sk = cd.cd_demo_sk
   AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wr.wr_reason_sk = r.r_reason_sk
  WHERE cp.cp_department = 'Books'
    AND p.p_response_target = 1
    AND w.w_state = 'CA'
    AND s.s_number_employees > 100
    AND i.inv_quantity_on_hand < 20
    AND cs.cs_sold_date_sk BETWEEN 2451150 AND 2451159
    AND cr.cr_return_amount > 50
),
agg AS (
  SELECT
    cp_department,
    cp_catalog_page_number,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cr_net_loss + sr_net_loss + wr_net_loss) AS total_return_loss,
    AVG(inv_quantity_on_hand) AS avg_inv_on_hand,
    cs_sold_date_sk
  FROM base
  GROUP BY cp_department, cp_catalog_page_number, cs_sold_date_sk
)
SELECT
  agg.cp_department,
  agg.cp_catalog_page_number,
  agg.total_net_profit,
  agg.total_return_loss,
  DENSE_RANK() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank,
  AVG(agg.avg_inv_on_hand) OVER (PARTITION BY agg.cp_department) AS dept_avg_inventory_on_hand,
  (SELECT AVG(cs2.cs_net_profit)
     FROM catalog_sales cs2
     WHERE cs2.cs_sold_date_sk = agg.cs_sold_date_sk) AS avg_daily_profit
FROM agg
ORDER BY profit_rank
LIMIT 100
