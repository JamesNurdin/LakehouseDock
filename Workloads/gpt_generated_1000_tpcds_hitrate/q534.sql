WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        cs_call_center_sk AS call_center_sk,
        cs_order_number AS order_number,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(CASE WHEN cs_ext_discount_amt > 0 THEN cs_ext_discount_amt ELSE 0 END) AS total_discount
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY cs_bill_customer_sk, cs_call_center_sk, cs_order_number
)

SELECT
    s.s_store_name,
    c.c_preferred_cust_flag,
    hd.hd_vehicle_count,
    cc.cc_name,
    r.r_reason_desc,
    SUM(CASE WHEN wr.wr_fee > 30 THEN wr.wr_fee ELSE 0 END) AS high_fee_sum,
    SUM(cs_agg.total_net_paid) AS catalog_net_paid,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    COUNT(DISTINCT cs_agg.order_number) AS distinct_orders
FROM cs_agg
JOIN customer c
    ON cs_agg.customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON cs_agg.call_center_sk = cc.cc_call_center_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
   AND ss.ss_hdemo_sk = hd.hd_demo_sk
RIGHT OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_returns wr
    ON wr.wr_returning_customer_sk = c.c_customer_sk
   AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
    AND hd.hd_vehicle_count >= 2
    AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
    AND s.s_state = 'CA'
GROUP BY
    s.s_store_name,
    c.c_preferred_cust_flag,
    hd.hd_vehicle_count,
    cc.cc_name,
    r.r_reason_desc
HAVING SUM(cs_agg.total_net_paid) > 10000

UNION

SELECT
    s.s_store_name,
    c.c_preferred_cust_flag,
    hd.hd_vehicle_count,
    cc.cc_name,
    r.r_reason_desc,
    SUM(CASE WHEN wr.wr_fee > 30 THEN wr.wr_fee ELSE 0 END) AS high_fee_sum,
    SUM(cs_agg.total_net_paid) AS catalog_net_paid,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    COUNT(DISTINCT cs_agg.order_number) AS distinct_orders
FROM cs_agg
JOIN customer c
    ON cs_agg.customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON cs_agg.call_center_sk = cc.cc_call_center_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
   AND ss.ss_hdemo_sk = hd.hd_demo_sk
RIGHT OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_returns wr
    ON wr.wr_returning_customer_sk = c.c_customer_sk
   AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    c.c_preferred_cust_flag = 'N'
    AND hd.hd_vehicle_count <= 1
    AND cc.cc_gmt_offset < -4.00
    AND s.s_state = 'TX'
GROUP BY
    s.s_store_name,
    c.c_preferred_cust_flag,
    hd.hd_vehicle_count,
    cc.cc_name,
    r.r_reason_desc
HAVING SUM(cs_agg.total_net_paid) > 5000
LIMIT 100
