WITH cs_agg AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_sold_date_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_qty
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1220
    AND cs.cs_wholesale_cost > 10
  GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
sr_store AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    sr.sr_store_sk,
    sr.sr_return_quantity,
    sr.sr_item_sk
  FROM store s
  FULL OUTER JOIN store_returns sr
    ON s.s_store_sk = sr.sr_store_sk
)
SELECT
  d.d_date,
  i.i_item_id,
  i.i_product_name,
  cs_agg.total_sales,
  cs_agg.total_qty,
  SUM(cs_agg.total_sales) OVER (
    PARTITION BY i.i_item_sk
    ORDER BY d.d_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_sales,
  CASE
    WHEN cs_agg.total_qty > 100 THEN 'High'
    WHEN cs_agg.total_qty > 50 THEN 'Medium'
    ELSE 'Low'
  END AS qty_category,
  p.p_promo_name,
  s_store.s_store_name,
  s_store.sr_return_quantity,
  wc.web_customer_cnt,
  (SELECT MAX(ws2.ws_sales_price)
   FROM web_sales ws2
   WHERE ws2.ws_item_sk = i.i_item_sk) AS max_web_price,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    ) THEN 1 ELSE 0
  END AS has_catalog_return
FROM cs_agg
JOIN catalog_sales cs
  ON cs.cs_item_sk = cs_agg.cs_item_sk
 AND cs.cs_sold_date_sk = cs_agg.cs_sold_date_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca_addr
  ON cs.cs_bill_addr_sk = ca_addr.ca_address_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cpg
  ON cs.cs_catalog_page_sk = cpg.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN sr_store s_store
  ON s_store.sr_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
  SELECT COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt
  FROM web_sales ws
  WHERE ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
) wc ON TRUE
WHERE cc.cc_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND p.p_discount_active = 'Y'
  AND d.d_month_seq BETWEEN 1210 AND 1220
ORDER BY d.d_date DESC, cs_agg.total_sales DESC
LIMIT 100
