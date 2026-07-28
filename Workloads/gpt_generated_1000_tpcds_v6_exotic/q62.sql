WITH sales AS (
  SELECT
    d.d_year,
    p.p_promo_name,
    r.r_reason_desc,
    SUM(ss.ss_net_paid)                         AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number)         AS sales_cnt,
    AVG(ss.ss_ext_discount_amt)                AS avg_discount,
    CAST(NULL AS decimal(7,2))                  AS total_returns,
    CAST(NULL AS bigint)                        AS returns_cnt,
    CAST(NULL AS decimal(7,2))                  AS avg_return_tax
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.catalog_sales cs ON cs.cs_bill_addr_sk = ca.ca_address_sk
                               AND cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
  JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND p.p_channel_catalog = 'N'
    AND cc.cc_state = 'CA'
    AND s.s_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND ws.web_country = 'US'
  GROUP BY GROUPING SETS (
    (d.d_year, p.p_promo_name, r.r_reason_desc),
    (d.d_year, p.p_promo_name),
    (d.d_year)
  )
),
returns AS (
  SELECT
    d.d_year,
    p.p_promo_name,
    r.r_reason_desc,
    CAST(NULL AS decimal(7,2))                  AS total_sales,
    CAST(NULL AS bigint)                        AS sales_cnt,
    CAST(NULL AS decimal(7,2))                  AS avg_discount,
    SUM(cr.cr_return_amount)                    AS total_returns,
    COUNT(*)                                    AS returns_cnt,
    AVG(cr.cr_return_tax)                       AS avg_return_tax
  FROM tpcds.date_dim d
  JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN tpcds.catalog_sales cs ON cs.cs_order_number = cr.cr_order_number
                               AND cs.cs_item_sk = cr.cr_item_sk
  JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND ws.web_country = 'US'
    AND r.r_reason_desc LIKE '%damaged%'
  GROUP BY GROUPING SETS (
    (d.d_year, p.p_promo_name, r.r_reason_desc),
    (d.d_year, p.p_promo_name),
    (d.d_year)
  )
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY d_year, p_promo_name, r_reason_desc
