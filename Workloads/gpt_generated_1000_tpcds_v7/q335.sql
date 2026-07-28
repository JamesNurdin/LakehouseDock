WITH base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_net_profit,
    cs.cs_order_number,
    d.d_year,
    t.t_hour,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    cc.cc_market_manager,
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    ca.ca_state,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    ss.ss_net_profit AS ss_net_profit,
    ss.ss_ticket_number,
    s.s_store_name,
    s.s_state,
    wr.wr_return_amt,
    wp.wp_web_page_id,
    ws.web_name
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws
    ON wp.wp_creation_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND i.i_brand = 'Brand#23'
    AND s.s_state = 'CA'
    AND cc.cc_market_manager = 'Ronald Somerville'
)
SELECT
  d_year,
  s_store_name,
  i_item_id,
  i_product_name,
  cs_order_number,
  (cs_net_profit + ss_net_profit) AS total_profit,
  CASE WHEN (cs_net_profit + ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
  RANK() OVER (PARTITION BY s_store_name ORDER BY (cs_net_profit + ss_net_profit) DESC) AS profit_rank
FROM base
ORDER BY profit_rank
LIMIT 100
