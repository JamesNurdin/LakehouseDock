WITH sales_details AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_ext_ship_cost,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cp.cp_department,
        cp.cp_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    -- semi‑join to call_center using IN (acts as an EXISTS filter)
    WHERE cs.cs_call_center_sk IN (
        SELECT cc.cc_call_center_sk
        FROM tpcds.call_center cc
        WHERE cc.cc_city = 'Glendale'
          AND cc.cc_company = 3
          AND cc.cc_state = 'CA'
    )
    AND cs.cs_quantity > 5                                   -- predicate 1
    AND cs.cs_ext_sales_price > 1000.00                      -- predicate 2
    AND cs.cs_ext_ship_cost BETWEEN 500.00 AND 3000.00      -- predicate 3
    AND ca.ca_country = 'United States'                     -- predicate 4
)
SELECT
    sd.cs_sold_date_sk,
    sd.c_first_name,
    sd.c_last_name,
    sd.ca_city,
    sd.ca_state,
    cc.cc_name,
    sd.cp_department,
    sd.cp_type,
    sd.cs_quantity,
    sd.cs_ext_sales_price,
    sd.cs_net_profit,
    RANK() OVER (PARTITION BY sd.cp_department ORDER BY sd.cs_net_profit DESC) AS dept_profit_rank,
    ROW_NUMBER() OVER (ORDER BY sd.cs_ext_sales_price DESC) AS overall_sales_rank,
    CASE
        WHEN sd.cs_net_profit > 5000 THEN 'High'
        WHEN sd.cs_net_profit BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_details sd
JOIN tpcds.call_center cc
    ON sd.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON sd.cs_catalog_page_sk = cp.cp_catalog_page_sk
ORDER BY sd.cs_net_profit DESC, sd.cs_ext_sales_price DESC
LIMIT 100
