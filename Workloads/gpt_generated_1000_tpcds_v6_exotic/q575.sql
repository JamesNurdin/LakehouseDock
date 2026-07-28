WITH base AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_date_sk AS sales_date_sk,
    i.i_category,
    cs.cs_net_profit AS catalog_net_profit,
    ss.ss_net_profit AS store_net_profit,
    cs.cs_ext_sales_price,
    ss.ss_ext_sales_price,
    cc.cc_company,
    sm.sm_type,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    t.t_hour,
    wr.wr_return_quantity,
    ws.web_site_id
  FROM store s
  JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN date_dim d_cat
    ON cs.cs_sold_date_sk = d_cat.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d_sales.d_date_sk
  LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
  WHERE d_sales.d_year = 1999
    AND i.i_category = 'Sports'
    AND cc.cc_company IN (2, 3)
    AND cs.cs_net_profit > 500
    AND ss.ss_net_profit > 200
    AND t.t_hour BETWEEN 8 AND 20
    AND ca.ca_state = 'CA'
)
SELECT
  s_store_sk,
  s_store_name,
  d_year,
  i_category,
  (catalog_net_profit + store_net_profit) AS total_net_profit,
  RANK() OVER (PARTITION BY d_year ORDER BY (catalog_net_profit + store_net_profit) DESC) AS profit_rank,
  DENSE_RANK() OVER (ORDER BY (catalog_net_profit + store_net_profit) DESC) AS overall_dense_rank,
  CASE WHEN ca_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag,
  (
    SELECT AVG(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    WHERE cs2.cs_sold_date_sk = base.sales_date_sk
  ) AS avg_daily_sales_price,
  SUM(wr_return_quantity) OVER (PARTITION BY s_store_sk) AS total_returns_qty
FROM base
WHERE NOT EXISTS (
  SELECT 1
  FROM store_returns sr2
  WHERE sr2.sr_store_sk = base.s_store_sk
    AND sr2.sr_net_loss > 0
)
ORDER BY total_net_profit DESC
LIMIT 100
