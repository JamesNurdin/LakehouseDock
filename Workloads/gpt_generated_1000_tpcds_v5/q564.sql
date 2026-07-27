WITH
  catalog_sales_agg AS (
    SELECT
      'catalog' AS sales_channel,
      s.s_state,
      SUM(cs.cs_net_paid) AS total_net_paid,
      AVG(cs.cs_ext_discount_amt) AS avg_discount,
      COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
      MIN(cs.cs_net_paid) AS min_net_paid,
      MAX(cs.cs_net_paid) AS max_net_paid
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d_sold.d_year = 2001
      AND i.i_category = 'Electronics'
      AND ca.ca_state = 'CA'
      AND hd.hd_income_band_sk BETWEEN 5 AND 7
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1
      AND EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
              AND p2.p_cost > 1000
          )
    GROUP BY s.s_state
  ),
  web_sales_agg AS (
    SELECT
      'web' AS sales_channel,
      s.s_state,
      SUM(ws.ws_net_paid) AS total_net_paid,
      AVG(ws.ws_ext_discount_amt) AS avg_discount,
      COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
      MIN(ws.ws_net_paid) AS min_net_paid,
      MAX(ws.ws_net_paid) AS max_net_paid
    FROM web_sales ws
    JOIN date_dim d_sold2 ON ws.ws_sold_date_sk = d_sold2.d_date_sk
    JOIN date_dim d_ship2 ON ws.ws_ship_date_sk = d_ship2.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ship2.d_date_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    WHERE d_sold2.d_year = 2002
      AND i2.i_category = 'Books'
      AND ca2.ca_state = 'NY'
      AND hd2.hd_income_band_sk BETWEEN 3 AND 5
      AND p2.p_discount_active = 'N'
      AND ws.ws_quantity > 2
      AND EXISTS (
            SELECT 1 FROM promotion p3
            WHERE p3.p_promo_sk = ws.ws_promo_sk
              AND p3.p_cost > 500
          )
    GROUP BY s.s_state
  )
SELECT *
FROM (
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
