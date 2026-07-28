WITH catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_date_sk AS date_sk,
        SUM(cs.cs_net_paid_inc_tax) AS amount,
        COUNT(*) AS txn_cnt,
        'catalog' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE cc.cc_division = 2
      AND cp.cp_catalog_number BETWEEN 100 AND 200
      AND c.c_preferred_cust_flag = 'Y'
      AND ca.ca_state = 'CA'
      AND d.d_year = 2001
      AND ws.web_class = 'Enterprise'
    GROUP BY cs.cs_bill_customer_sk, d.d_date_sk
),
store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        d2.d_date_sk AS date_sk,
        SUM(ss.ss_net_paid) AS amount,
        COUNT(*) AS txn_cnt,
        'store' AS src
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    JOIN customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
    JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c2.c_customer_sk
    JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws2 ON ws2.web_open_date_sk = d3.d_date_sk
    WHERE d2.d_year = 2001
      AND ss.ss_quantity > 1
      AND wr.wr_return_quantity > 0
      AND wp.wp_type = 'Content'
      AND ws2.web_tax_percentage > 0
    GROUP BY ss.ss_customer_sk, d2.d_date_sk
),
unified AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT
    u.customer_sk,
    COUNT(*) AS source_count,
    SUM(u.amount) AS total_amount,
    AVG(u.amount) AS avg_amount_per_source
FROM unified u
GROUP BY u.customer_sk
HAVING SUM(u.amount) > 10000
ORDER BY total_amount DESC
LIMIT 100
