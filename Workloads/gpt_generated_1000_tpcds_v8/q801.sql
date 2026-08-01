WITH cs AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_bill_addr_sk,
    cs.cs_ship_addr_sk,
    d.d_year,
    sm.sm_type
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  WHERE d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND sm.sm_type = 'OVERNIGHT'
    AND cs.cs_quantity > 1
    AND cs.cs_ext_sales_price > 100.00
    AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
    )
),
sr AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_returned_date_sk,
    sr.sr_return_time_sk,
    sr.sr_addr_sk,
    sr.sr_reason_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_net_loss
  FROM store_returns sr
  JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
  JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
  JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d2.d_year = 2001
    AND t2.t_hour BETWEEN 9 AND 17
    AND sr.sr_return_quantity > 0
    AND sr.sr_return_amt > 50.00
    AND sr.sr_net_loss > 0
),
promo_orders AS (
  SELECT cs_order_number
  FROM cs
  WHERE cs_ext_sales_price > 500
),
overnight_orders AS (
  SELECT cs_order_number
  FROM cs
  WHERE cs_quantity >= 5
),
order_excluded AS (
  SELECT cs_order_number FROM promo_orders
  EXCEPT
  SELECT cs_order_number FROM overnight_orders
),
return_tickets AS (
  SELECT sr_ticket_number
  FROM sr
  WHERE sr_return_amt > 200
),
common_keys AS (
  SELECT cs_order_number FROM cs
  INTERSECT
  SELECT sr_ticket_number FROM return_tickets
)
SELECT
  cs.d_year,
  cs.sm_type,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_net_profit) AS avg_profit,
  MIN(cs.cs_ext_sales_price) AS min_sale,
  MAX(cs.cs_ext_sales_price) AS max_sale,
  ROW_NUMBER() OVER (PARTITION BY cs.sm_type ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn_type
FROM cs
FULL OUTER JOIN sr
  ON cs.cs_bill_addr_sk = sr.sr_addr_sk
WHERE cs.cs_order_number IN (SELECT cs_order_number FROM order_excluded)
  AND cs.cs_order_number IN (SELECT cs_order_number FROM common_keys)
GROUP BY cs.d_year, cs.sm_type
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
