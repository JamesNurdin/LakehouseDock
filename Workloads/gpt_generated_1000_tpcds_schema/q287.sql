WITH
  cs_base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk          AS cs_item_sk,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_sold_date_sk,
      td.t_hour               AS cs_hour,
      c.c_customer_sk        AS c_customer_sk,
      cd.cd_demo_sk,
      cc.cc_call_center_sk,
      cp.cp_catalog_page_number,
      w.w_warehouse_sk,
      i.i_item_id,
      p.p_promo_id
    FROM catalog_sales cs
    JOIN time_dim td            ON cs.cs_sold_time_sk   = td.t_time_sk
    JOIN customer c             ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN item i                ON cs.cs_item_sk        = i.i_item_sk
    JOIN promotion p           ON cs.cs_promo_sk       = p.p_promo_sk
  ),

  ss_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_item_sk          AS ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_quantity,
      ss.ss_net_profit,
      td.t_hour               AS ss_hour,
      s.s_store_name,
      i.i_category,
      p.p_discount_active
    FROM store_sales ss
    FULL OUTER JOIN store s    ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td           ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
  ),

  ws_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk          AS ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_profit,
      td.t_hour               AS ws_hour,
      wp.wp_type,
      i.i_brand,
      p.p_promo_name,
      w.w_warehouse_sk
    FROM web_sales ws
    JOIN time_dim td          ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
  ),

  wr_base AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_order_number,
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      td.t_hour               AS wr_hour,
      i.i_brand               AS wr_brand,
      wp.wp_type              AS wr_page_type
    FROM web_returns wr
    JOIN time_dim td          ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i               ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
  )
SELECT
  cs_base.cs_order_number,
  cs_base.i_item_id,
  cs_base.p_promo_id,
  ss_base.s_store_name,
  ws_base.wp_type,
  SUM(cs_base.cs_net_profit)                         AS total_cs_profit,
  SUM(ss_base.ss_net_profit)                         AS total_ss_profit,
  SUM(ws_base.ws_net_profit)                         AS total_ws_profit,
  CASE WHEN SUM(cs_base.cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS cs_profit_flag,
  ROW_NUMBER() OVER (ORDER BY SUM(cs_base.cs_net_profit + ss_base.ss_net_profit + ws_base.ws_net_profit) DESC) AS rn,
  la.avg_discount
FROM cs_base
JOIN ss_base ON cs_base.cs_item_sk = ss_base.ss_item_sk
JOIN ws_base ON cs_base.cs_item_sk = ws_base.ws_item_sk
LEFT JOIN wr_base ON ws_base.ws_order_number = wr_base.wr_order_number
CROSS JOIN LATERAL (
  SELECT AVG(ss2.ss_quantity * ss2.ss_net_profit) AS avg_discount
  FROM store_sales ss2
  WHERE ss2.ss_customer_sk = cs_base.c_customer_sk
) la
GROUP BY
  cs_base.cs_order_number,
  cs_base.i_item_id,
  cs_base.p_promo_id,
  ss_base.s_store_name,
  ws_base.wp_type,
  la.avg_discount
ORDER BY total_cs_profit DESC
LIMIT 100
