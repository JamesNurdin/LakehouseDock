WITH
  filtered_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_profit,
      ws.ws_ext_ship_cost,
      ws.ws_ship_date_sk,
      ws.ws_promo_sk,
      ws.ws_ship_mode_sk,
      ws.ws_bill_cdemo_sk,
      p.p_promo_name,
      p.p_channel_radio,
      p.p_channel_catalog,
      p.p_channel_press,
      sm.sm_ship_mode_id,
      sm.sm_contract,
      cd.cd_gender,
      cd.cd_education_status
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_channel_radio = 'N'
      AND p.p_channel_catalog = 'N'
      AND p.p_channel_press = 'N'
      AND sm.sm_contract LIKE 'uuk%'
      AND ws.ws_ext_ship_cost > 100
      AND ws.ws_net_paid_inc_ship BETWEEN 1500 AND 4000
      AND ws.ws_ship_date_sk BETWEEN 2451400 AND 2452800
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
  ),
  agg_sales AS (
    SELECT
      p_promo_name,
      sm_ship_mode_id,
      sm_contract,
      COUNT(DISTINCT ws_order_number) AS orders,
      SUM(ws_net_profit) AS total_net_profit,
      AVG(ws_ext_ship_cost) AS avg_ship_cost
    FROM filtered_sales
    GROUP BY p_promo_name, sm_ship_mode_id, sm_contract
  )
SELECT
  p_promo_name,
  sm_ship_mode_id,
  sm_contract,
  orders,
  total_net_profit,
  avg_ship_cost,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
  SUM(total_net_profit) OVER (
    ORDER BY total_net_profit DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_profit
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 100
