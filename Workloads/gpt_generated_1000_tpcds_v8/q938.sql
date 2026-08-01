WITH item_promo AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    p.p_promo_sk,
    p.p_promo_name,
    p.p_discount_active
  FROM
    (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i
    FULL OUTER JOIN promotion p
      ON i.i_item_sk = p.p_item_sk
),

order_intersect AS (
  SELECT cs_order_number FROM (
    SELECT DISTINCT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
  )
  INTERSECT
  SELECT sr_ticket_number FROM (
    SELECT DISTINCT sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 2
  )
),

scalar_max_return_qty AS (
  SELECT MAX(sr_return_quantity) AS max_qty FROM store_returns
)

SELECT
  cs.cs_order_number,
  cs.cs_sold_date_sk,
  i.i_product_name,
  cc.cc_name,
  cp.cp_department,
  sm.sm_code,
  cd.cd_education_status,
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  LAG(cs.cs_sales_price) OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk) AS prev_sales_price,
  SUM(cs.cs_ext_sales_price) OVER (
    PARTITION BY i.i_brand
    ORDER BY cs.cs_sold_date_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS brand_running_sales,
  r.r_reason_desc,
  sr.sr_return_quantity,
  ip.p_promo_name,
  ip.p_discount_active
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN item_promo ip ON i.i_item_sk = ip.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
WHERE
  cp.cp_department = 'Sports'
  AND sm.sm_code = 'AIR'
  AND cd.cd_education_status = 'College'
  AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451453
  AND cs.cs_quantity > (SELECT max_qty FROM scalar_max_return_qty)
  AND cs.cs_order_number IN (SELECT cs_order_number FROM order_intersect)
ORDER BY cs.cs_net_profit DESC
LIMIT 100
