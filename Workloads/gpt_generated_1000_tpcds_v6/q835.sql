WITH sales_agg AS ( 
    SELECT 
        cc.cc_call_center_sk,
        cc.cc_company_name,
        cp.cp_department,
        hd.hd_demo_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_net_paid) AS avg_paid,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_hours = '8AM-4PM'
      AND cc.cc_company_name IN ('able', 'pri')
      AND cp.cp_department = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND hd.hd_vehicle_count >= 1
      AND cs.cs_quantity > 0
    GROUP BY cc.cc_call_center_sk, cc.cc_company_name, cp.cp_department, hd.hd_demo_sk
),
returns_agg AS ( 
    SELECT 
        wr.wr_refunded_hdemo_sk,
        r.r_reason_desc,
        wp.wp_autogen_flag,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc LIKE '%color%'
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count >= 4
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY wr.wr_refunded_hdemo_sk, r.r_reason_desc, wp.wp_autogen_flag
)
SELECT 
    s.cc_company_name,
    s.cp_department,
    s.total_profit,
    s.sales_cnt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    CASE WHEN s.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank,
    (SELECT AVG(total_profit) FROM sales_agg) AS avg_profit_all_cc
FROM sales_agg s
LEFT JOIN returns_agg r ON s.hd_demo_sk = r.wr_refunded_hdemo_sk
WHERE s.total_quantity > 10
  AND s.total_profit IS NOT NULL
ORDER BY profit_rank
LIMIT 100
