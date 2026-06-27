WITH sales_agg AS (
   SELECT
       p.p_promo_id,
       p.p_promo_name,
       ws.ws_promo_sk,
       ws.ws_item_sk,
       SUM(ws.ws_quantity) AS total_quantity,
       SUM(ws.ws_ext_sales_price) AS total_sales_amount,
       SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
       SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
       COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_ship_modes,
       COUNT(DISTINCT ws.ws_warehouse_sk) AS distinct_warehouses
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE p.p_item_sk = i.i_item_sk
   GROUP BY p.p_promo_id, p.p_promo_name, ws.ws_promo_sk, ws.ws_item_sk
),
returns_agg AS (
   SELECT
       p.p_promo_id,
       p.p_promo_name,
       ws.ws_promo_sk,
       ws.ws_item_sk,
       SUM(wr.wr_return_quantity) AS total_return_quantity,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_net_loss) AS total_return_loss
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE p.p_item_sk = i.i_item_sk
   GROUP BY p.p_promo_id, p.p_promo_name, ws.ws_promo_sk, ws.ws_item_sk
)
SELECT
   s.p_promo_id,
   s.p_promo_name,
   s.total_quantity,
   COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
   s.total_sales_amount,
   COALESCE(r.total_return_amount, 0) AS total_return_amount,
   s.total_discount_amount,
   s.total_ship_cost,
   s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
   s.distinct_customers,
   s.distinct_ship_modes,
   s.distinct_warehouses
FROM sales_agg s
LEFT JOIN returns_agg r
   ON s.p_promo_id = r.p_promo_id
   AND s.ws_item_sk = r.ws_item_sk
ORDER BY s.total_sales_amount DESC
LIMIT 20
