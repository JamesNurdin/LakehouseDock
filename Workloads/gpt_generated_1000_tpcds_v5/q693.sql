WITH sales_enriched AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid_inc_ship,
    ws.ws_ext_tax,
    ws.ws_quantity,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    w.w_warehouse_name,
    w.w_city,
    p.p_promo_name,
    p.p_discount_active
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  WHERE
    ws.ws_ext_tax > 10
    AND ws.ws_net_paid_inc_ship BETWEEN 1000 AND 5000
    AND ws.ws_quantity >= 1
    AND d_sold.d_year = 2001
    AND w.w_city IN ('Elm Madison', 'Lincoln Adams')
    AND p.p_discount_active = 'Y'
)
SELECT
  se.ws_order_number,
  se.ws_net_paid_inc_ship,
  se.ws_ext_tax,
  se.sold_year,
  se.ship_year,
  se.bill_state,
  se.ship_state,
  se.w_warehouse_name,
  se.w_city,
  se.p_promo_name,
  RANK() OVER (PARTITION BY se.w_city ORDER BY se.ws_net_paid_inc_ship DESC) AS city_sales_rank,
  ROW_NUMBER() OVER (ORDER BY se.ws_ext_tax DESC) AS tax_desc_rownum,
  CASE
    WHEN se.ws_ext_tax > 100 THEN 'High Tax'
    WHEN se.ws_ext_tax > 50 THEN 'Medium Tax'
    ELSE 'Low Tax'
  END AS tax_category
FROM sales_enriched se
ORDER BY se.ws_net_paid_inc_ship DESC, se.ws_order_number
LIMIT 100
