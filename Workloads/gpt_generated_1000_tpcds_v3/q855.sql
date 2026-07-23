WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_paid,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 500
      AND cs.cs_quantity >= 2
      AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451940
      AND cs.cs_ext_tax > 0
      AND cs.cs_ext_discount_amt < 100
      AND cs.cs_coupon_amt = 0
),
agg_sales AS (
    SELECT
        cc.cc_name,
        cp.cp_type,
        c.c_customer_id,
        cd.cd_credit_rating,
        c.c_preferred_cust_flag,
        SUM(fs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT fs.cs_order_number) AS distinct_orders
    FROM filtered_sales fs
    JOIN call_center cc
        ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON fs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_gmt_offset >= -8
      AND cp.cp_type IN ('monthly', 'quarterly')
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_college_count >= 2
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
            AND cs2.cs_net_paid > 10000
      )
    GROUP BY
        cc.cc_name,
        cp.cp_type,
        c.c_customer_id,
        cd.cd_credit_rating,
        c.c_preferred_cust_flag
    HAVING COUNT(DISTINCT fs.cs_order_number) >= 3
)
SELECT
    cc_name,
    cp_type,
    c_customer_id,
    cd_credit_rating,
    c_preferred_cust_flag,
    total_net_paid,
    RANK() OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC) AS rank_by_center,
    ROW_NUMBER() OVER (PARTITION BY cp_type ORDER BY total_net_paid DESC) AS row_num_by_type
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 10
