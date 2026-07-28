WITH
  distinct_cc AS (
    SELECT DISTINCT cc_call_center_sk, cc_company_name, cc_state
    FROM call_center
  ),
  cs_agg AS (
    SELECT
      cs.cs_call_center_sk,
      cs.cs_warehouse_sk,
      cs.cs_sold_date_sk,
      SUM(cs.cs_net_profit)      AS total_profit,
      SUM(cs.cs_quantity)        AS total_quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_sold_date_sk
  )
SELECT
  d_date.d_year,
  CASE WHEN cc.cc_state = 'CA' THEN 'West' ELSE 'Other' END               AS region_category,
  cc.cc_company_name,
  w.w_warehouse_name,
  wp.wp_type,
  SUM(ss.ss_net_profit)                                                    AS store_profit,
  SUM(ws.ws_net_profit)                                                    AS web_profit,
  cs_agg.total_profit,
  ROW_NUMBER() OVER (PARTITION BY cc.cc_company_name ORDER BY cs_agg.total_profit DESC) AS profit_rank
FROM cs_agg
JOIN distinct_cc cc               ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w                  ON cs_agg.cs_warehouse_sk   = w.w_warehouse_sk
JOIN date_dim d_date              ON cs_agg.cs_sold_date_sk  = d_date.d_date_sk
JOIN store_sales ss               ON ss.ss_sold_date_sk      = d_date.d_date_sk
JOIN customer_demographics cd_ss  ON ss.ss_cdemo_sk          = cd_ss.cd_demo_sk
JOIN web_sales ws                 ON ws.ws_sold_date_sk      = d_date.d_date_sk
JOIN web_page wp                  ON ws.ws_web_page_sk       = wp.wp_web_page_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN warehouse w2                 ON ws.ws_warehouse_sk      = w2.w_warehouse_sk
JOIN date_dim d_ship_ws           ON ws.ws_ship_date_sk      = d_ship_ws.d_date_sk
WHERE d_date.d_year BETWEEN 2000 AND 2002
GROUP BY
  d_date.d_year,
  CASE WHEN cc.cc_state = 'CA' THEN 'West' ELSE 'Other' END,
  cc.cc_company_name,
  w.w_warehouse_name,
  wp.wp_type,
  cs_agg.total_profit,
  cc.cc_state
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY store_profit DESC
LIMIT 100
