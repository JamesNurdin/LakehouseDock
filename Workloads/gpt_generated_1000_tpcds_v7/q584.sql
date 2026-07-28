WITH joined AS (
  SELECT
    d.d_year,
    w.w_warehouse_name,
    ca.ca_state,
    cs.cs_ext_sales_price,
    cs.cs_order_number,
    ws.ws_ext_sales_price,
    ws.ws_order_number,
    inv.inv_quantity_on_hand,
    cs.cs_net_profit,
    ws.ws_net_profit
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
    AND w.w_warehouse_sq_ft > 500000
    AND ca.ca_state IN ('CA', 'TX')
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 8 AND 20
),
aggregated AS (
  SELECT
    d_year,
    w_warehouse_name,
    ca_state,
    SUM(cs_ext_sales_price) AS catalog_sales_total,
    SUM(ws_ext_sales_price) AS web_sales_total,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders
  FROM joined
  GROUP BY d_year, w_warehouse_name, ca_state
  HAVING SUM(cs_ext_sales_price + ws_ext_sales_price) > 1000000
)
SELECT
  AVG(catalog_sales_total + web_sales_total) AS avg_combined_sales_per_group
FROM aggregated
