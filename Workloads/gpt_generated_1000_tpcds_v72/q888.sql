WITH base_sales AS (
  SELECT
    ss.ss_sold_date_sk          AS date_sk,
    ss.ss_sold_time_sk          AS time_sk,
    ss.ss_item_sk               AS item_sk,
    ss.ss_customer_sk           AS customer_sk,
    ss.ss_cdemo_sk              AS cdemo_sk,
    ss.ss_hdemo_sk              AS hdemo_sk,
    ss.ss_addr_sk               AS addr_sk,
    CAST(NULL AS integer)       AS ship_mode_sk,
    CAST(NULL AS integer)       AS warehouse_sk,
    ss.ss_net_profit            AS net_profit,
    ss.ss_quantity              AS quantity,
    CAST(NULL AS integer)       AS order_number
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_bill_hdemo_sk,
    ws.ws_bill_addr_sk,
    ws.ws_ship_mode_sk,
    ws.ws_warehouse_sk,
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_order_number
  FROM web_sales ws
),
joined_sales AS (
  SELECT
    bs.*,                                          -- all columns from the UNION
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    c.c_customer_id,
    ca.ca_country,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    w.w_warehouse_name,
    wr.wr_return_quantity,
    CASE WHEN bs.net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    (SELECT AVG(net_profit) FROM base_sales)       AS avg_profit_overall
  FROM base_sales bs
  JOIN date_dim d          ON bs.date_sk = d.d_date_sk
  JOIN time_dim t          ON bs.time_sk = t.t_time_sk
  JOIN item i              ON bs.item_sk = i.i_item_sk
  JOIN customer c          ON bs.customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON bs.cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON bs.hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON bs.addr_sk = ca.ca_address_sk
  LEFT JOIN ship_mode sm  ON bs.ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse w   ON bs.warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_returns wr ON bs.order_number = wr.wr_order_number
  LEFT JOIN inventory inv   ON inv.inv_date_sk = d.d_date_sk
                              AND inv.inv_item_sk = i.i_item_sk
                              AND (bs.warehouse_sk IS NOT NULL AND inv.inv_warehouse_sk = bs.warehouse_sk)
  LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  LEFT JOIN income_band ib   ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2000 AND 2002                       -- predicate 1
    AND i.i_brand_id = 10                                    -- predicate 2
    AND ca.ca_country = 'United States'                     -- predicate 3
    AND ib.ib_upper_bound > 50000                            -- predicate 4
),
aggregated AS (
  SELECT
    c_customer_id,
    d_year,
    i_category,
    profit_flag,
    ib_lower_bound,
    SUM(net_profit)   AS total_profit,
    COUNT(*)          AS sales_cnt,
    AVG(net_profit)   AS avg_profit,
    MAX(avg_profit_overall) AS overall_avg_profit
  FROM joined_sales
  GROUP BY
    c_customer_id,
    d_year,
    i_category,
    profit_flag,
    ib_lower_bound,
    avg_profit_overall
)
SELECT
  c_customer_id,
  d_year,
  i_category,
  profit_flag,
  ib_lower_bound,
  total_profit,
  sales_cnt,
  avg_profit,
  overall_avg_profit
FROM aggregated
WHERE total_profit > 0                                   -- HAVING‑like filter after aggregation
ORDER BY total_profit DESC
LIMIT 100
