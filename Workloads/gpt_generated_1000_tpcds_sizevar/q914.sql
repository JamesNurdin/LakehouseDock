WITH
  sampled_cs AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),
  joined AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      ca.ca_state,
      cd.cd_gender,
      cc.cc_name,
      cp.cp_department,
      sm.sm_type,
      p.p_promo_name,
      cs.cs_net_profit,
      cs.cs_order_number,
      ws.ws_order_number AS ws_order_number,
      sr.sr_ticket_number,
      t.t_hour,
      CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      item_sales.item_total_sales
    FROM sampled_cs cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
     AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_return_time_sk = t.t_time_sk
     AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN LATERAL (
      SELECT SUM(cs2.cs_ext_sales_price) AS item_total_sales
      FROM catalog_sales cs2
      WHERE cs2.cs_item_sk = cs.cs_item_sk
    ) item_sales ON true
    WHERE d.d_year = 2001
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND cc.cc_market_manager IS NOT NULL
      AND i.i_color = 'BLUE'
      AND t.t_hour BETWEEN 8 AND 12
  ),
  aggregated AS (
    SELECT
      d_year,
      i_category,
      i_brand,
      profit_flag,
      COUNT(*) AS orders_count,
      SUM(cs_net_profit) AS total_profit,
      AVG(cs_net_profit) AS avg_profit,
      MAX(item_total_sales) AS max_item_sales,
      RANK() OVER (PARTITION BY i_category ORDER BY SUM(cs_net_profit) DESC) AS profit_rank,
      DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS order_dense_rank
    FROM joined
    GROUP BY CUBE (d_year, i_category, i_brand, profit_flag)
    HAVING COUNT(*) > 5
  ),
  profit_rows AS (
    SELECT * FROM aggregated WHERE profit_flag = 'Profit'
  ),
  loss_rows AS (
    SELECT * FROM aggregated WHERE profit_flag = 'Loss'
  )
SELECT *
FROM (
  SELECT * FROM profit_rows
  EXCEPT
  SELECT * FROM loss_rows
) final_set
ORDER BY total_profit DESC
LIMIT 100
