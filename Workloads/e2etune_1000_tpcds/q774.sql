WITH sales_by_center AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_bill_cdemo_sk
    FROM catalog_sales cs
),
agg AS (
    SELECT
        cc.cc_manager AS manager,
        cc.cc_name,
        cc.cc_employees,
        SUM(sbc.cs_net_profit) AS total_net_profit,
        AVG(sbc.cs_ext_discount_amt) AS avg_discount_amount,
        SUM(sbc.cs_quantity) AS total_quantity_sold,
        SUM(sbc.cs_net_profit) / NULLIF(cc.cc_employees, 0) AS profit_per_employee
    FROM sales_by_center sbc
    JOIN call_center cc
        ON sbc.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd
        ON sbc.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        cc.cc_country = 'United States'
        AND cc.cc_employees > 2000000
        AND cd.cd_education_status = 'College'
        AND cd.cd_purchase_estimate > 5000
    GROUP BY
        cc.cc_manager,
        cc.cc_name,
        cc.cc_employees
)
SELECT
    manager,
    cc_name,
    cc_employees,
    total_net_profit,
    avg_discount_amount,
    total_quantity_sold,
    profit_per_employee,
    RANK() OVER (ORDER BY profit_per_employee DESC) AS profit_per_employee_rank
FROM agg
ORDER BY profit_per_employee DESC
LIMIT 10
