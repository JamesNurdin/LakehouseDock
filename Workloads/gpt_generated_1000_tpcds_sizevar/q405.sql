WITH address_zips AS (
  SELECT ca_state,
         array_agg(ca_zip) AS zip_arr
  FROM customer_address
  GROUP BY ca_state
),

sales_data AS (
  SELECT
    s.s_store_id,
    ds.d_year,
    s.s_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit
  FROM store_sales ss TABLESAMPLE BERNOULLI (10)
  JOIN date_dim ds               ON ss.ss_sold_date_sk   = ds.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk      = hd.hd_demo_sk
  JOIN customer_address ca       ON ss.ss_addr_sk       = ca.ca_address_sk
  JOIN store s                   ON ss.ss_store_sk      = s.s_store_sk
  LEFT JOIN inventory inv        ON inv.inv_date_sk     = ds.d_date_sk
  LEFT JOIN warehouse w          ON inv.inv_warehouse_sk = w.w_warehouse_sk
  GROUP BY s.s_store_id, ds.d_year, s.s_state
),

return_data AS (
  SELECT
    cr.cr_order_number,
    dr.d_year,
    sm.sm_type,
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss)      AS total_net_loss
  FROM catalog_returns cr
  JOIN date_dim dr               ON cr.cr_returned_date_sk = dr.d_date_sk
  JOIN ship_mode sm              ON cr.cr_ship_mode_sk    = sm.sm_ship_mode_sk
  JOIN warehouse w               ON cr.cr_warehouse_sk    = w.w_warehouse_sk
  GROUP BY cr.cr_order_number, dr.d_year, sm.sm_type, w.w_warehouse_name
),

web_return_data AS (
  SELECT
    wr.wr_order_number,
    dw.d_year,
    ws.web_name,
    SUM(wr.wr_return_amt) AS total_web_return,
    SUM(wr.wr_net_loss)   AS total_web_net_loss
  FROM web_returns wr
  JOIN date_dim dw   ON wr.wr_returned_date_sk = dw.d_date_sk
  JOIN web_site ws   ON ws.web_open_date_sk    = dw.d_date_sk
  GROUP BY wr.wr_order_number, dw.d_year, ws.web_name
),

combined AS (
  SELECT
    sd.s_store_id   AS key_id,
    sd.d_year,
    sd.s_state,
    sd.total_sales,
    sd.total_profit,
    rd.total_return_amount,
    rd.total_net_loss,
    wrd.total_web_return,
    wrd.total_web_net_loss
  FROM sales_data sd
  JOIN return_data rd   ON sd.d_year = rd.d_year
  JOIN web_return_data wrd ON sd.d_year = wrd.d_year
)
SELECT
  c.key_id,
  c.d_year,
  c.s_state,
  c.total_sales,
  c.total_profit,
  c.total_return_amount,
  c.total_net_loss,
  c.total_web_return,
  c.total_web_net_loss,
  t.zip
FROM (
  SELECT key_id, d_year, s_state, total_sales, total_profit,
         total_return_amount, total_net_loss,
         total_web_return, total_web_net_loss
  FROM combined
  INTERSECT
  SELECT key_id, d_year, s_state, total_sales, total_profit,
         total_return_amount, total_net_loss,
         total_web_return, total_web_net_loss
  FROM combined
) c
JOIN address_zips az ON c.s_state = az.ca_state
CROSS JOIN UNNEST(az.zip_arr) AS t(zip)
ORDER BY c.total_sales DESC
LIMIT 100
