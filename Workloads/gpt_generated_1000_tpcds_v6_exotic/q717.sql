WITH agg_by_customer AS (
    SELECT
        c.c_customer_id,
        cc.cc_name,
        r.r_reason_desc,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(ss.ss_net_paid_inc_tax) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_month IN (1, 5, 9, 11)
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cc.cc_mkt_class LIKE '%workers%'
      AND cc.cc_gmt_offset > -5.00
      AND ss.ss_list_price > 20.00
      AND cr.cr_return_quantity >= 1
    GROUP BY c.c_customer_id, cc.cc_name, r.r_reason_desc
)
SELECT
    sales_category,
    AVG(total_sales) AS avg_total_sales,
    SUM(total_refunded_cash) AS sum_refunded_cash,
    COUNT(*) AS num_customers
FROM agg_by_customer a
WHERE NOT EXISTS (
    SELECT 1
    FROM call_center cc2
    WHERE cc2.cc_name = a.cc_name
      AND cc2.cc_tax_percentage > 10.00
)
GROUP BY sales_category
HAVING AVG(total_sales) > 5000
ORDER BY avg_total_sales DESC
LIMIT 100
