WITH
base_data AS (
    SELECT
        cc.cc_name,
        cc.cc_country,
        cc.cc_gmt_offset,
        cp.cp_department,
        cp.cp_type,
        p.p_channel_catalog,
        p.p_cost,
        cd.cd_gender,
        cd.cd_dep_college_count,
        ca.ca_state,
        ca.ca_country,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        r.r_reason_desc,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
            AND p.p_channel_catalog = 'N'
            AND p.p_cost > 1000.00
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
            AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        cc.cc_rec_start_date >= DATE '1999-01-01'
        AND cc.cc_rec_end_date <= DATE '2002-12-31'
        AND cd.cd_dep_college_count >= 1
        AND ca.ca_country = 'United States'
        AND cp.cp_department = 'Electronics'
        AND cs.cs_quantity > 0
),

sales_agg AS (
    SELECT
        cc_name,
        cp_department,
        r_reason_desc,
        SUM(cs_ext_sales_price) AS sales_amount,
        SUM(cs_net_profit) AS profit_amount,
        'sales' AS src
    FROM base_data
    GROUP BY ROLLUP (cc_name, cp_department, r_reason_desc)
),

returns_agg AS (
    SELECT
        cc_name,
        cp_department,
        r_reason_desc,
        SUM(cr_return_amount) AS sales_amount,
        -SUM(cr_net_loss) AS profit_amount,
        'returns' AS src
    FROM base_data
    WHERE cr_return_quantity > 0
    GROUP BY ROLLUP (cc_name, cp_department, r_reason_desc)
),

combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
)
SELECT
    c.cc_name,
    c.cp_department,
    c.r_reason_desc,
    c.src,
    c.sales_amount,
    c.profit_amount,
    DENSE_RANK() OVER (PARTITION BY c.cc_name ORDER BY c.profit_amount DESC) AS profit_rank,
    CASE WHEN c.profit_amount > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
    (SELECT AVG(c2.profit_amount)
     FROM combined c2
     WHERE c2.cc_name = c.cc_name) AS avg_profit_by_cc,
    (SELECT MAX(c3.sales_amount)
     FROM combined c3
     WHERE c3.cp_department = c.cp_department) AS max_sales_in_dept
FROM combined c
WHERE c.profit_amount > (
    SELECT AVG(c4.profit_amount)
    FROM combined c4
    WHERE c4.cc_name = c.cc_name
)
ORDER BY c.cc_name, profit_rank
LIMIT 100
