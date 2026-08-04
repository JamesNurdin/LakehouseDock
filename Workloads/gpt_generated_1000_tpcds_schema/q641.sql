WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
first_part AS (
    SELECT
        cc.cc_state,
        cp.cp_department,
        cs.cs_order_number,
        cs.cs_net_paid,
        (
            SELECT SUM(cr.cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
        ) AS total_return_amount
    FROM sales_sample cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND cs.cs_list_price > 100
),
second_part AS (
    SELECT
        cc.cc_state,
        cp.cp_department,
        cs.cs_order_number,
        cs.cs_net_paid,
        (
            SELECT SUM(cr.cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
        ) AS total_return_amount
    FROM sales_sample cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE cc.cc_state = 'TX'
      AND cs.cs_list_price > 50
),
union_all AS (
    SELECT cc_state, cp_department, cs_order_number, cs_net_paid, total_return_amount
    FROM first_part
    UNION
    SELECT cc_state, cp_department, cs_order_number, cs_net_paid, total_return_amount
    FROM second_part
),
grouped AS (
    SELECT
        cc_state,
        cp_department,
        SUM(cs_net_paid) AS sum_net_paid,
        SUM(total_return_amount) AS sum_return_amount,
        COUNT(*) AS order_cnt
    FROM union_all
    GROUP BY ROLLUP (cc_state, cp_department)
)
SELECT
    cc_state,
    cp_department,
    sum_net_paid,
    sum_return_amount,
    order_cnt,
    ROW_NUMBER() OVER (ORDER BY sum_net_paid DESC) AS rn
FROM grouped
ORDER BY sum_net_paid DESC
LIMIT 100
