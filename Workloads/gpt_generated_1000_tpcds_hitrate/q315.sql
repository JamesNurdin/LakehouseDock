WITH sales_site AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid_inc_ship_tax,
    ws.ws_coupon_amt,
    ws.ws_quantity,
    ws.ws_ship_customer_sk,
    ws.ws_web_site_sk,
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_ext_tax,
    ws.ws_ext_ship_cost,
    ws.ws_net_profit,
    ws.ws_ext_wholesale_cost,
    ws.ws_ext_list_price,
    ws.ws_sales_price,
    ws.ws_wholesale_cost,
    ws.ws_list_price,
    ws.ws_net_paid,
    ws.ws_ship_mode_sk,
    ws.ws_warehouse_sk,
    ws.ws_promo_sk,
    map(
      array['net_paid_inc_ship_tax','coupon_amt','quantity','ext_sales_price'],
      array[ws.ws_net_paid_inc_ship_tax, ws.ws_coupon_amt, ws.ws_quantity, ws.ws_ext_sales_price]
    ) AS metric_map
  FROM web_sales ws
  JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE wsit.web_mkt_id IN (3,5)
    AND ws.ws_net_paid_inc_ship_tax > 1000
)

SELECT
  combined.ws_order_number,
  combined.site_name,
  metric_name,
  metric_value
FROM (
  SELECT
    ss.ws_order_number AS ws_order_number,
    wsit.web_name AS site_name,
    ss.metric_map
  FROM sales_site ss
  JOIN web_site wsit
    ON ss.ws_web_site_sk = wsit.web_site_sk
  WHERE wsit.web_company_id = 3

  UNION ALL

  SELECT
    ws.ws_order_number AS ws_order_number,
    wsit.web_name AS site_name,
    map(
      array['net_paid_inc_ship_tax','coupon_amt','quantity','ext_sales_price'],
      array[ws.ws_net_paid_inc_ship_tax, ws.ws_coupon_amt, ws.ws_quantity, ws.ws_ext_sales_price]
    ) AS metric_map
  FROM web_sales ws
  FULL OUTER JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE (wsit.web_tax_percentage IS NULL OR wsit.web_tax_percentage > 0.07)
    AND (ws.ws_quantity >= 5 OR ws.ws_quantity IS NULL)
) AS combined
CROSS JOIN UNNEST(combined.metric_map) AS t(metric_name, metric_value)
ORDER BY metric_value DESC
LIMIT 100
