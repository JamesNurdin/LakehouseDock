-- goal: Analyze return and sales performance by ship mode and time shift, filtering on contract, code, meal time and fees, then compare per‑ship‑mode aggregates using set operations and window functions.
WITH joined AS (
   SELECT
      cr.cr_return_amount,
      cr.cr_net_loss,
      cr.cr_return_quantity,
      cr.cr_ship_mode_sk,
      wr.wr_return_amt,
      wr.wr_fee,
      wr.wr_net_loss,
      sm.sm_ship_mode_id,
      sm.sm_contract,
      sm.sm_code,
      td.t_sub_shift,
      td.t_meal_time,
      p.p_discount_active,
      ws.ws_quantity,
      ws.ws_sold_time_sk,
      ws.ws_ship_mode_sk,
      ws.ws_promo_sk,
      ws.ws_web_page_sk,
      wp.wp_web_page_id,
      wsite.web_site_sk
   FROM catalog_returns cr
   JOIN time_dim td
     ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_sales ws
     ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite
     ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN web_returns wr
     ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE
      sm.sm_contract IN ('I3uCelXtjP','YvxVaJI10')
      AND sm.sm_code IN ('AIR','SEA')
      AND td.t_sub_shift IN ('morning','afternoon')
      AND td.t_meal_time = 'lunch'
      AND p.p_discount_active = 'Y'
      AND wr.wr_fee > 20
      AND cr.cr_return_quantity > 0
      AND ws.ws_quantity > 0
),
agg1 AS (
   SELECT
      sm_ship_mode_id,
      t_sub_shift,
      SUM(cr_return_amount + wr_return_amt) AS total_return_amount,
      SUM(cr_net_loss + wr_net_loss) AS total_net_loss,
      COUNT(*) AS cnt_transactions
   FROM joined
   GROUP BY sm_ship_mode_id, t_sub_shift
),
agg2 AS (
   SELECT
      sm_ship_mode_id,
      AVG(total_net_loss) AS avg_net_loss,
      SUM(total_return_amount) AS sum_return_amount
   FROM agg1
   GROUP BY sm_ship_mode_id
),
select_a AS (
   SELECT
      sm_ship_mode_id,
      total_return_amount,
      total_net_loss,
      ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_return_amount DESC) AS rn,
      SUM(total_return_amount) OVER (PARTITION BY sm_ship_mode_id ORDER BY total_return_amount DESC ROWS UNBOUNDED PRECEDING) AS running_total_return
   FROM agg1
   WHERE total_return_amount > 1500
),
select_b AS (
   SELECT
      sm_ship_mode_id,
      sum_return_amount AS total_return_amount,
      avg_net_loss AS total_net_loss,
      ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY sum_return_amount DESC) AS rn,
      SUM(sum_return_amount) OVER (PARTITION BY sm_ship_mode_id ORDER BY sum_return_amount DESC ROWS UNBOUNDED PRECEDING) AS running_total_return
   FROM agg2
   WHERE avg_net_loss > 200
),
union_set AS (
   SELECT sm_ship_mode_id, total_return_amount, total_net_loss, rn, running_total_return
   FROM select_a
   UNION
   SELECT sm_ship_mode_id, total_return_amount, total_net_loss, rn, running_total_return
   FROM select_b
),
final_set AS (
   SELECT *
   FROM union_set
   EXCEPT
   SELECT sm_ship_mode_id, total_return_amount, total_net_loss, rn, running_total_return
   FROM union_set
   WHERE rn > 3
)
SELECT
   sm_ship_mode_id,
   total_return_amount,
   total_net_loss,
   rn,
   running_total_return
FROM final_set
ORDER BY total_return_amount DESC
LIMIT 100
