WITH cs_agg AS (
    SELECT
        cs_catalog_page_sk,
        cs_bill_addr_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_sold_time_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
        AND cs_list_price > 50
        AND cs_net_paid > 0
        AND cs_sold_date_sk BETWEEN 2450815 AND 2451815
        AND cs_sold_time_sk IS NOT NULL
    GROUP BY cs_catalog_page_sk, cs_bill_addr_sk, cs_bill_cdemo_sk, cs_bill_hdemo_sk, cs_sold_time_sk
)
SELECT DISTINCT
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_description,
    ca.ca_city AS address_city,
    ca.ca_state AS address_state,
    cd.cd_gender,
    hd.hd_vehicle_count,
    total_sales.total_net_paid,
    total_sales.sales_cnt,
    sr.sr_return_amt,
    wr.wr_return_amt,
    wp.wp_url,
    RANK() OVER (PARTITION BY s.s_state ORDER BY total_sales.total_net_paid DESC) AS state_sales_rank,
    ROW_NUMBER() OVER (ORDER BY total_sales.total_net_paid DESC) AS overall_sales_rownum,
    CASE
        WHEN total_sales.total_net_paid > (SELECT AVG(total_net_paid) FROM cs_agg) THEN 'High'
        ELSE 'Low'
    END AS sales_category
FROM cs_agg total_sales
JOIN catalog_page cp ON total_sales.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca ON total_sales.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON total_sales.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON total_sales.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t ON total_sales.cs_sold_time_sk = t.t_time_sk
JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
    AND sr.sr_addr_sk = ca.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_returning_addr_sk = ca.ca_address_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE ca.ca_state = 'TX'
    AND ca.ca_county IN ('York County', 'Marshall County')
    AND cp.cp_department = 'Electronics'
    AND s.s_state = 'CA'
    AND hd.hd_vehicle_count >= 1
    AND t.t_hour BETWEEN 8 AND 20
    AND wp.wp_type = 'Content'
    AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_amt > 1000
    )
    AND wr.wr_return_amt > 0
ORDER BY total_sales.total_net_paid DESC
OFFSET 0
LIMIT 100
