WITH joined AS (
  SELECT
    d.d_year,
    i.i_category,
    cd.cd_gender,
    r.r_reason_desc,
    sm.sm_code,
    sm.sm_type,
    c.c_customer_sk,
    i.i_item_sk,
    ss.ss_net_profit,
    sr.sr_return_quantity,
    wr.wr_return_quantity,
    cr.cr_return_quantity
  FROM date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON i.i_item_sk = ss.ss_item_sk
  JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
  JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
  JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
  JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
  JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                       AND sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                           AND cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
  JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND i.i_category = 'Sports'
    AND cd.cd_gender = 'M'
    AND r.r_reason_id = 'AAAAAAAAGAAAAAAA'
    AND sm.sm_code = 'AIR'
    AND ib.ib_lower_bound >= 20000
    AND NOT EXISTS (
      SELECT 1 FROM web_returns wr2
      WHERE wr2.wr_returning_customer_sk = c.c_customer_sk
    )
),
exploded AS (
  SELECT
    j.*, 
    mode_attribute
  FROM joined j
  CROSS JOIN UNNEST(ARRAY[j.sm_code, j.sm_type]) AS t(mode_attribute)
),
agg AS (
  SELECT
    d_year,
    i_category,
    cd_gender,
    r_reason_desc,
    sm_code,
    mode_attribute,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_sign,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    COUNT(DISTINCT i_item_sk) AS distinct_items,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(sr_return_quantity + wr_return_quantity + cr_return_quantity) AS total_return_qty
  FROM exploded
  GROUP BY
    d_year,
    i_category,
    cd_gender,
    r_reason_desc,
    sm_code,
    mode_attribute
)
SELECT
  d_year,
  i_category,
  cd_gender,
  r_reason_desc,
  sm_code,
  mode_attribute,
  profit_sign,
  distinct_customers,
  distinct_items,
  total_net_profit,
  total_return_qty,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank, total_net_profit DESC
LIMIT 100
