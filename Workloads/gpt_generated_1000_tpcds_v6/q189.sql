WITH sales_returns AS (
    SELECT
        cc.cc_call_center_id AS cc_call_center_id,
        cc.cc_mkt_class AS cc_mkt_class,
        cc.cc_hours AS cc_hours,
        wp.wp_web_page_id AS wp_web_page_id,
        wp.wp_type AS wp_type,
        cs.cs_order_number AS cs_order_number,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_sales_price AS cs_sales_price,
        cr.cr_return_amount AS cr_return_amount,
        wr.wr_return_amt AS wr_return_amt,
        ca_bill.ca_gmt_offset AS ca_gmt_offset
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_mkt_class = 'Psychiatric'
      AND cc.cc_hours = '8AM-4PM'
      AND ca_bill.ca_gmt_offset = -6.00
      AND cs.cs_net_paid > 0
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
)
SELECT
    cc_call_center_id,
    wp_web_page_id,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(cr_return_amount) AS total_catalog_return,
    SUM(wr_return_amt) AS total_web_return,
    CASE
        WHEN SUM(cs_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag,
    RANK() OVER (ORDER BY SUM(cs_net_paid) DESC) AS sales_rank,
    (SELECT AVG(cs_net_profit) FROM catalog_sales) AS overall_avg_profit
FROM sales_returns
GROUP BY cc_call_center_id, wp_web_page_id
HAVING COUNT(DISTINCT cs_order_number) >= 10
ORDER BY total_sales DESC
LIMIT 100
