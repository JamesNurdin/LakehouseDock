WITH sales_agg AS (
  SELECT
    ds.d_year,
    ds.d_moy,
    i.i_category,
    w.w_state,
    s.web_name,
    sum(ws.ws_ext_sales_price) AS total_sales,
    sum(ws.ws_quantity) AS total_quantity,
    sum(ws.ws_ext_discount_amt) AS total_discount,
    sum(ws.ws_net_profit) AS total_profit,
    count(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
  FROM web_sales ws
  JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
  WHERE ds.d_date >= DATE '2022-01-01' AND ds.d_date < DATE '2023-01-01'
  GROUP BY ds.d_year, ds.d_moy, i.i_category, w.w_state, s.web_name
),

returns_agg AS (
  SELECT
    dr.d_year,
    dr.d_moy,
    i.i_category,
    w.w_state,
    s.web_name,
    sum(wr.wr_return_amt) AS total_return_amount,
    sum(wr.wr_net_loss) AS total_return_loss,
    sum(wr.wr_return_quantity) AS total_return_quantity
  FROM web_returns wr
  JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
  WHERE dr.d_date >= DATE '2022-01-01' AND dr.d_date < DATE '2023-01-01'
  GROUP BY dr.d_year, dr.d_moy, i.i_category, w.w_state, s.web_name
)

SELECT
  s.d_year,
  s.d_moy,
  s.i_category,
  s.w_state,
  s.web_name,
  s.total_sales,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales_amount,
  s.total_discount,
  s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
  s.total_quantity,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  s.distinct_customers
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_moy = r.d_moy
 AND s.i_category = r.i_category
 AND s.w_state = r.w_state
 AND s.web_name = r.web_name
ORDER BY s.d_year DESC, s.d_moy DESC, s.i_category, s.w_state, s.web_name
