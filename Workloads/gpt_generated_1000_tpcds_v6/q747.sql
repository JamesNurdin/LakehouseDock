WITH base AS (
  SELECT
    i.i_category,
    i.i_class,
    sm.sm_type,
    cc.cc_state,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    wr.wr_return_amt,
    cs.cs_order_number,
    r.r_reason_desc,
    wp.wp_type
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cc.cc_state = 'CA'
    AND cs.cs_sold_date_sk >= 2450000
    AND cs.cs_quantity > 1
    AND i.i_current_price >= 20
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_cost > 10
    )
    AND r.r_reason_desc LIKE '%missing%'
    AND wp.wp_type = 'C'
)
SELECT
    i_category,
    i_class,
    sm_type,
    SUM(cs_net_paid) AS total_sales,
    SUM(wr_return_amt) AS total_returns,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(cs_net_paid) DESC) AS sales_rank_in_category,
    (SELECT AVG(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS avg_active_promo_cost
FROM base
GROUP BY GROUPING SETS (
    (i_category, i_class, sm_type),
    (i_category, i_class),
    (i_category, sm_type),
    (i_category),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
