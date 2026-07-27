WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_cr_amount,
        COUNT(*) AS cr_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_item_sk, cr_returned_date_sk
)
SELECT
    d.d_year,
    i.i_brand,
    s.s_state,
    sm.sm_type,
    p.p_discount_active,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(cr_agg.total_cr_amount) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(ws.ws_ship_date_sk) AS min_ship_date_sk,
    MAX(ws.ws_ship_date_sk) AS max_ship_date_sk
FROM cr_agg
JOIN catalog_returns cr
  ON cr.cr_item_sk = cr_agg.cr_item_sk
 AND cr.cr_returned_date_sk = cr_agg.cr_returned_date_sk
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_address ca_refunded
  ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN date_dim d_ws
  ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws
  ON ws.ws_promo_sk = p_ws.p_promo_sk
WHERE
    d.d_year = 2021
    AND i.i_brand = 'Brand#23'
    AND s.s_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'M'
    AND t.t_sub_shift = 'morning'
GROUP BY
    d.d_year,
    i.i_brand,
    s.s_state,
    sm.sm_type,
    p.p_discount_active,
    cd.cd_gender
ORDER BY total_net_profit DESC
LIMIT 100
