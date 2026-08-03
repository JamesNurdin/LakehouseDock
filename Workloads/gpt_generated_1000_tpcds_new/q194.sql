WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        cs.cs_wholesale_cost,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid
    FROM
        catalog_sales cs
    WHERE
        cs.cs_quantity > 5
        AND cs.cs_sales_price > 100
        AND cs.cs_wholesale_cost BETWEEN 20 AND 100
        AND cs.cs_ext_ship_cost < 5000
        AND cs.cs_coupon_amt <> 0
        AND cs.cs_net_profit IS NOT NULL
)
SELECT
    cs.cs_order_number,
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    ca.ca_state,
    cp.cp_department,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_ext_sales_price,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = cs.cs_catalog_page_sk
    ) AS page_total_sales,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY cs.cs_net_profit DESC) AS profit_state_rank
FROM filtered_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE
    d_sold.d_year = 2002
    AND d_sold.d_month_seq BETWEEN 1 AND 12
    AND cp.cp_department = 'Electronics'
    AND ca.ca_country = 'United States'
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND cp.cp_type = 'Catalog'
ORDER BY profit_state_rank, cs.cs_net_profit DESC
LIMIT 100
