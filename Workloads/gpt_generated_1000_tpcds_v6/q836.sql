WITH
  sales_agg AS (
    SELECT
      cs.cs_bill_customer_sk   AS cust_sk,
      cs.cs_bill_cdemo_sk      AS cdemo_sk,
      cs.cs_bill_addr_sk       AS addr_sk,
      cs.cs_call_center_sk     AS call_center_sk,
      cs.cs_catalog_page_sk    AS catalog_page_sk,
      cs.cs_ship_mode_sk       AS ship_mode_sk,
      cs.cs_warehouse_sk       AS warehouse_sk,
      cs.cs_promo_sk           AS promo_sk,
      CAST(NULL AS integer)   AS store_sk,
      SUM(cs.cs_net_paid)      AS sales_amount,
      COUNT(*)                 AS sales_cnt,
      CASE WHEN SUM(cs.cs_ext_discount_amt) > 0 THEN 'DISCOUNTED' ELSE 'FULLPRICE' END AS sales_type
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_list_price > 100
      AND cs.cs_quantity > 1
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451170
    GROUP BY
      cs.cs_bill_customer_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_promo_sk
  ),
  returns_agg AS (
    SELECT
      sr.sr_customer_sk        AS cust_sk,
      sr.sr_cdemo_sk           AS cdemo_sk,
      sr.sr_addr_sk            AS addr_sk,
      CAST(NULL AS integer)   AS call_center_sk,
      CAST(NULL AS integer)   AS catalog_page_sk,
      CAST(NULL AS integer)   AS ship_mode_sk,
      CAST(NULL AS integer)   AS warehouse_sk,
      CAST(NULL AS integer)   AS promo_sk,
      sr.sr_store_sk           AS store_sk,
      SUM(sr.sr_return_amt)   AS sales_amount,
      COUNT(*)                 AS sales_cnt,
      'RETURN'                 AS sales_type
    FROM tpcds.store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_returned_date_sk BETWEEN 2450815 AND 2451170
    GROUP BY
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_addr_sk,
      sr.sr_store_sk
  ),
  all_transactions AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  at.sales_type,
  SUM(at.sales_amount)               AS total_amount,
  SUM(at.sales_cnt)                  AS total_txns,
  CASE WHEN SUM(at.sales_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
  MIN(at.sales_amount)               AS min_amount,
  MAX(at.sales_amount)               AS max_amount,
  COUNT(DISTINCT p.p_promo_id)       AS promo_used_cnt,
  COUNT(DISTINCT wp.wp_web_page_id)  AS web_page_cnt
FROM all_transactions at
JOIN tpcds.customer c               ON at.cust_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON at.cdemo_sk = cd.cd_demo_sk
JOIN tpcds.customer_address ca      ON at.addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.call_center cc       ON at.call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.catalog_page cp      ON at.catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN tpcds.ship_mode sm         ON at.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN tpcds.warehouse w          ON at.warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.promotion p          ON at.promo_sk = p.p_promo_sk
LEFT JOIN tpcds.store s              ON at.store_sk = s.s_store_sk
LEFT JOIN tpcds.web_returns wr       ON c.c_customer_sk = wr.wr_refunded_customer_sk
LEFT JOIN tpcds.web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE c.c_birth_month = 7
  AND ca.ca_state = 'CA'
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  at.sales_type
ORDER BY total_amount DESC
LIMIT 100
