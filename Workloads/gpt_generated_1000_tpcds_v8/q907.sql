WITH sales_agg AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       SUM(ss.ss_net_paid) AS total_sales,
       COUNT(*) AS sales_cnt,
       MAX(ss.ss_sold_date_sk) AS last_sale_date_sk,
       CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 9 AND 17
     AND p.p_discount_active = 'Y'
     AND ca.ca_country = 'United States'
     AND cd.cd_gender = 'M'
     AND ss.ss_quantity > 0
     AND ss.ss_sales_price > 0
   GROUP BY c.c_customer_sk, c.c_customer_id
),
returns_agg AS (
   SELECT
       c.c_customer_sk,
       SUM(cr.cr_return_amount) AS total_returns,
       COUNT(*) AS return_cnt,
       CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'HIGH_RET' ELSE 'LOW_RET' END AS return_category
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE w.w_state = 'CA'
     AND sm.sm_carrier = 'FEDEX'
     AND r.r_reason_desc LIKE '%defect%'
     AND t.t_hour BETWEEN 0 AND 23
     AND cr.cr_return_quantity > 0
     AND cr.cr_fee < 100
   GROUP BY c.c_customer_sk
),
inventory_agg AS (
   SELECT
       w.w_warehouse_sk,
       SUM(inv.inv_quantity_on_hand) AS total_on_hand
   FROM inventory inv
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_country = 'United States'
   GROUP BY w.w_warehouse_sk
),
web_pages AS (
   SELECT
       c.c_customer_sk,
       wp.wp_url,
       wp.wp_char_count
   FROM web_page wp
   JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
   WHERE wp.wp_type = 'home'
),
customer_metrics AS (
   SELECT
       s.c_customer_sk,
       s.c_customer_id,
       s.total_sales,
       s.sales_category,
       COALESCE(r.total_returns, 0) AS total_returns,
       COALESCE(r.return_category, 'NONE') AS return_category,
       s.sales_cnt,
       COALESCE(r.return_cnt, 0) AS return_cnt,
       (s.total_sales - COALESCE(r.total_returns, 0)) AS net_amount
   FROM sales_agg s
   LEFT JOIN returns_agg r ON s.c_customer_sk = r.c_customer_sk
),
customer_with_page AS (
   SELECT
       cm.*,
       wp.wp_url,
       wp.wp_char_count
   FROM customer_metrics cm
   LEFT JOIN LATERAL (
       SELECT wp_url, wp_char_count
       FROM web_pages wp
       WHERE wp.c_customer_sk = cm.c_customer_sk
       ORDER BY wp.wp_char_count DESC
       LIMIT 1
   ) wp ON TRUE
),
customer_inventory AS (
   SELECT
       cw.*,
       w.w_warehouse_name,
       i.total_on_hand
   FROM customer_with_page cw
   LEFT JOIN catalog_returns cr ON cw.c_customer_sk = cr.cr_refunded_customer_sk
   LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN inventory_agg i ON w.w_warehouse_sk = i.w_warehouse_sk
)
SELECT
    c.c_customer_id,
    c.net_amount,
    c.sales_category,
    c.return_category,
    c.wp_url,
    c.wp_char_count,
    c.w_warehouse_name,
    c.total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY c.sales_category ORDER BY c.net_amount DESC) AS rank_in_category,
    SUM(c.net_amount) OVER (PARTITION BY c.sales_category) AS category_total_net
FROM customer_inventory c
WHERE c.net_amount > 0
  AND c.sales_category = 'HIGH'
  AND c.return_category <> 'HIGH_RET'
  AND (c.wp_char_count IS NULL OR c.wp_char_count > 1000)
  AND (c.total_on_hand IS NULL OR c.total_on_hand > 500)
  AND c.c_customer_id IS NOT NULL
UNION
SELECT
    c.c_customer_id,
    c.net_amount,
    c.sales_category,
    c.return_category,
    c.wp_url,
    c.wp_char_count,
    c.w_warehouse_name,
    c.total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY c.sales_category ORDER BY c.net_amount ASC) AS rank_in_category,
    SUM(c.net_amount) OVER (PARTITION BY c.sales_category) AS category_total_net
FROM customer_inventory c
WHERE c.net_amount <= 0
  AND c.sales_category = 'LOW'
  AND c.return_category = 'LOW_RET'
  AND c.wp_char_count IS NOT NULL AND c.wp_char_count < 2000
  AND c.total_on_hand IS NOT NULL AND c.total_on_hand < 1000
  AND c.c_customer_id IS NOT NULL
EXCEPT
SELECT
    c.c_customer_id,
    c.net_amount,
    c.sales_category,
    c.return_category,
    c.wp_url,
    c.wp_char_count,
    c.w_warehouse_name,
    c.total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY c.sales_category ORDER BY c.net_amount DESC) AS rank_in_category,
    SUM(c.net_amount) OVER (PARTITION BY c.sales_category) AS category_total_net
FROM customer_inventory c
WHERE c.sales_cnt = 0 AND c.return_cnt > 0
ORDER BY net_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
