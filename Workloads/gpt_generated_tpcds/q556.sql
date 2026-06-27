WITH sales_agg AS (
   SELECT
       p.p_promo_name,
       d_sold.d_year,
       d_sold.d_moy,
       sm.sm_type,
       w.w_warehouse_name,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_net_profit) AS total_profit
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
   GROUP BY p.p_promo_name, d_sold.d_year, d_sold.d_moy, sm.sm_type, w.w_warehouse_name
),
returns_agg AS (
   SELECT
       p.p_promo_name,
       d_ret.d_year,
       d_ret.d_moy,
       sm.sm_type,
       w.w_warehouse_name,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_net_loss) AS total_return_loss
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
   GROUP BY p.p_promo_name, d_ret.d_year, d_ret.d_moy, sm.sm_type, w.w_warehouse_name
)
SELECT
   s.p_promo_name,
   s.d_year,
   s.d_moy,
   s.sm_type,
   s.w_warehouse_name,
   s.total_sales,
   s.total_profit,
   COALESCE(r.total_return_amount, 0) AS total_return_amount,
   COALESCE(r.total_return_loss, 0) AS total_return_loss,
   CASE WHEN s.total_sales = 0 THEN 0 ELSE COALESCE(r.total_return_amount, 0) / s.total_sales END AS return_rate
FROM sales_agg s
LEFT JOIN returns_agg r
   ON s.p_promo_name = r.p_promo_name
  AND s.d_year = r.d_year
  AND s.d_moy = r.d_moy
  AND s.sm_type = r.sm_type
  AND s.w_warehouse_name = r.w_warehouse_name
ORDER BY s.total_profit DESC
LIMIT 100
