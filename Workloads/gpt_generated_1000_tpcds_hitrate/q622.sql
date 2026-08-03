WITH
  date_store_sales AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_net_profit,
      ss.ss_sold_date_sk,
      d.d_date,
      i.i_item_sk,
      i.i_category,
      i.i_category_id,
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      p.p_promo_sk,
      p.p_discount_active,
      cd.cd_gender,
      hd.hd_income_band_sk,
      CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_net_profit * 1.10 ELSE ss.ss_net_profit END AS adj_net_profit,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_net_profit DESC) AS rn_store
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_current_year = 'Y'
      AND i.i_category_id IN (1, 3, 8)
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
  ),
  date_web_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_profit,
      ws.ws_sold_date_sk,
      d.d_date,
      i.i_item_sk,
      i.i_category,
      i.i_category_id,
      p.p_promo_sk,
      p.p_discount_active,
      cd.cd_gender,
      hd.hd_income_band_sk,
      CASE WHEN p.p_discount_active = 'Y' THEN ws.ws_net_profit * 1.05 ELSE ws.ws_net_profit END AS adj_net_profit,
      ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY ws.ws_net_profit DESC) AS rn_item
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_current_quarter = 'Y'
      AND i.i_category_id IN (1, 3, 8)
      AND p.p_discount_active = 'Y'
  ),
  call_center_dates AS (
    SELECT
      cc.cc_call_center_id,
      d.d_date,
      d.d_current_quarter,
      CASE WHEN d.d_current_quarter = 'Y' THEN 1 ELSE 0 END AS is_current_quarter
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
  ),
  combined AS (
    SELECT
      ds.s_store_name AS store_name,
      ds.i_category AS category,
      ds.adj_net_profit AS adj_profit,
      cc.is_current_quarter
    FROM date_store_sales ds
    JOIN call_center_dates cc ON ds.d_date = cc.d_date
    WHERE ds.rn_store <= 5
      AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = ds.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
    UNION ALL
    SELECT
      NULL AS store_name,
      dw.i_category AS category,
      dw.adj_net_profit AS adj_profit,
      cc.is_current_quarter
    FROM date_web_sales dw
    JOIN call_center_dates cc ON dw.d_date = cc.d_date
    WHERE dw.rn_item <= 5
  ),
  agg AS (
    SELECT
      store_name,
      category,
      SUM(adj_profit) AS total_adj_profit,
      COUNT(*) AS txn_cnt,
      AVG(adj_profit) AS avg_adj_profit,
      MAX(adj_profit) AS max_adj_profit,
      MIN(adj_profit) AS min_adj_profit,
      SUM(CASE WHEN is_current_quarter = 1 THEN adj_profit ELSE 0 END) AS current_quarter_profit
    FROM combined
    GROUP BY store_name, category, is_current_quarter
    HAVING COUNT(*) > 1
  )
SELECT
  store_name,
  category,
  total_adj_profit,
  txn_cnt,
  avg_adj_profit,
  max_adj_profit,
  min_adj_profit,
  current_quarter_profit,
  LAG(total_adj_profit) OVER (PARTITION BY store_name ORDER BY total_adj_profit DESC) AS prev_store_profit,
  SUM(total_adj_profit) OVER (ORDER BY total_adj_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_profit,
  ROW_NUMBER() OVER (ORDER BY total_adj_profit DESC) AS rank_overall
FROM agg
ORDER BY total_adj_profit DESC
OFFSET 0 LIMIT 100
