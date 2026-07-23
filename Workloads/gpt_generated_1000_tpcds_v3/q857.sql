WITH
store_sales_agg AS (
    SELECT
        'store' AS sales_type,
        s.s_store_id AS id,
        s.s_store_name AS description,
        d.d_year,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(*) AS txn_cnt,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ca.ca_location_type = 'apartment'
      AND p.p_discount_active = 'Y'
      AND cc.cc_class = 'A'
      AND t.t_hour >= 12
      AND ws.web_city = 'San Francisco'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, p.p_promo_name
),
catalog_sales_agg AS (
    SELECT
        'catalog' AS sales_type,
        cp.cp_catalog_page_id AS id,
        cp.cp_description AS description,
        d.d_year,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(*) AS txn_cnt,
        AVG(cs.cs_net_paid) AS avg_net_paid
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_location_type = 'single family'
      AND p.p_discount_active = 'Y'
      AND cc.cc_class = 'B'
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY cp.cp_catalog_page_id, cp.cp_description, d.d_year, p.p_promo_name
),
union_sales AS (
    SELECT sales_type, id, description, d_year, promo_name, net_paid, txn_cnt, avg_net_paid
    FROM store_sales_agg
    UNION ALL
    SELECT sales_type, id, description, d_year, promo_name, net_paid, txn_cnt, avg_net_paid
    FROM catalog_sales_agg
),
overall_agg AS (
    SELECT
        sales_type,
        d_year,
        SUM(net_paid) AS total_net_paid,
        AVG(net_paid) AS avg_net_paid,
        SUM(txn_cnt) AS total_txn_cnt
    FROM union_sales
    GROUP BY sales_type, d_year
)
SELECT
    oa.sales_type,
    oa.d_year,
    oa.total_net_paid,
    oa.avg_net_paid,
    oa.total_txn_cnt
FROM overall_agg oa
WHERE oa.total_net_paid > (SELECT AVG(total_net_paid) FROM overall_agg)
  AND oa.avg_net_paid > 500
  AND oa.total_txn_cnt >= 10
  AND oa.sales_type IN ('store', 'catalog')
ORDER BY oa.total_net_paid DESC
LIMIT 100
