WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_list_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_list_price > 100
      AND cs.cs_ship_mode_sk IN (7, 10, 20)
      AND cs.cs_ext_sales_price IS NOT NULL
)
SELECT
    cc.cc_name,
    cc.cc_company_name,
    cp.cp_department,
    cp.cp_catalog_number,
    ca.ca_city,
    ca.ca_state,
    fs.cs_ext_sales_price,
    fs.cs_net_profit,
    RANK() OVER (PARTITION BY cc.cc_company_name ORDER BY fs.cs_net_profit DESC) AS profit_rank,
    SUM(fs.cs_ext_sales_price) OVER (
        PARTITION BY cc.cc_company_name
        ORDER BY fs.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM filtered_sales fs
JOIN call_center cc
  ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca
  ON fs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cc.cc_class = 'large'
  AND cc.cc_company_name = 'cally'
  AND cc.cc_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  AND ca.ca_location_type = 'condo'
ORDER BY profit_rank, fs.cs_net_profit DESC
LIMIT 100
