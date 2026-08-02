/* Goal: Calculate per‑customer profit categories for high‑value orders in fiscal year 1915, including only orders that appear in both catalog and web sales, have active promotions, sufficient warehouse capacity, and no associated web returns. */
WITH order_intersect AS (
  SELECT cs.cs_order_number AS order_number
  FROM catalog_sales cs
  WHERE cs.cs_net_paid > 0
  INTERSECT
  SELECT ws.ws_order_number
  FROM web_sales ws
  WHERE ws.ws_net_paid > 0
),
base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    ws.ws_net_profit,
    c.c_customer_id            AS c_customer_id,
    d.d_year                   AS d_year,
    p.p_discount_active,
    w.w_warehouse_sq_ft,
    i.inv_quantity_on_hand,
    r.r_reason_desc,
    tp.t_hour,
    wp.wp_max_ad_count,
    CASE
      WHEN cs.cs_net_profit > 1000 THEN 'High'
      WHEN cs.cs_net_profit > 0    THEN 'Medium'
      ELSE 'Low'
    END                         AS profit_category
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim tp
    ON cs.cs_sold_time_sk = tp.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
   AND i.inv_date_sk      = d.d_date_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_date_sk    = d.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r
    ON r.r_reason_sk = wr.wr_reason_sk
  WHERE d.d_year = 1915
    AND p.p_discount_active = 'Y'
    AND w.w_warehouse_sq_ft > 50000
    AND i.inv_quantity_on_hand > 0
    AND tp.t_hour BETWEEN 8 AND 20
    AND wp.wp_max_ad_count >= 2
    AND cs.cs_order_number IN (SELECT order_number FROM order_intersect)
    AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_order_number = ws.ws_order_number
        )
)
SELECT
  c_customer_id,
  d_year,
  profit_category,
  SUM(cs_net_profit)               AS sum_cs_profit,
  SUM(ws_net_profit)               AS sum_ws_profit,
  SUM(cs_net_profit + ws_net_profit) AS total_profit,
  COUNT(DISTINCT cs_order_number)   AS orders_count
FROM base
GROUP BY
  c_customer_id,
  d_year,
  profit_category
HAVING SUM(cs_net_profit + ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
