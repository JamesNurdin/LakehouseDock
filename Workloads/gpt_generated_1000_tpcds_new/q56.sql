WITH unified_data AS (
   SELECT
       cs.cs_order_number,
       cs.cs_quantity,
       cs.cs_net_paid_inc_tax,
       cs.cs_net_profit,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       r.r_reason_desc,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       t.t_hour,
       t.t_shift,
       ws.ws_order_number,
       ws.ws_quantity AS ws_quantity,
       ws.ws_net_paid_inc_tax AS ws_net_paid_inc_tax,
       ws.ws_net_profit AS ws_net_profit
   FROM catalog_sales cs
   JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
   JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
   JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cs.cs_quantity >= 2
     AND cs.cs_net_paid_inc_tax > 500
     AND t.t_hour BETWEEN 9 AND 17
     AND hd.hd_buy_potential = '1001-5000'
     AND ib.ib_upper_bound <= 90000
     AND cr.cr_return_quantity IS NOT NULL
     AND ws.ws_net_paid_inc_tax > 1000
     AND ws.ws_quantity BETWEEN 1 AND 5
)
SELECT
    ud.r_reason_desc,
    ud.hd_buy_potential,
    ud.t_shift,
    COUNT(DISTINCT ud.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ud.ws_order_number) AS web_orders,
    SUM(ud.cs_quantity) AS total_catalog_qty,
    SUM(ud.ws_quantity) AS total_web_qty,
    AVG(ud.cs_net_paid_inc_tax) AS avg_catalog_paid,
    AVG(ud.ws_net_paid_inc_tax) AS avg_web_paid,
    SUM(ud.cr_net_loss) AS total_return_loss,
    MIN(ud.cs_net_profit) AS min_catalog_profit,
    MAX(ud.ws_net_profit) AS max_web_profit
FROM unified_data ud
WHERE ud.cs_net_profit > (
      SELECT MAX(cr2.cr_net_loss)
      FROM catalog_returns cr2
      WHERE cr2.cr_return_quantity > 1
)
GROUP BY
    ud.r_reason_desc,
    ud.hd_buy_potential,
    ud.t_shift
ORDER BY total_return_loss DESC, catalog_orders DESC
LIMIT 100
