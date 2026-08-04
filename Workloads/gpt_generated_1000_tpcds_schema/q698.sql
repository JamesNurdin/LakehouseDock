WITH sales_agg AS (
        SELECT
            cs_bill_customer_sk AS cust_sk,
            SUM(cs_net_paid_inc_ship) AS total_sales,
            COUNT(DISTINCT cs_order_number) AS distinct_orders,
            SUM(cs_ext_discount_amt) AS total_discount
        FROM catalog_sales
        WHERE cs_net_paid_inc_ship > 1000
          AND cs_ext_list_price BETWEEN 500 AND 10000
          AND cs_quantity >= 1
        GROUP BY cs_bill_customer_sk
    ),
    returns_agg AS (
        SELECT
            wr_refunded_customer_sk AS cust_sk,
            SUM(wr_return_amt_inc_tax) AS total_returns,
            COUNT(DISTINCT wr_order_number) AS distinct_return_orders,
            SUM(wr_reversed_charge) AS total_rev_charge
        FROM web_returns
        WHERE wr_return_amt_inc_tax > 100
          AND wr_return_quantity > 0
          AND wr_account_credit < 50
        GROUP BY wr_refunded_customer_sk
    ),
    union_sets AS (
        SELECT cust_sk FROM sales_agg
        UNION
        SELECT cust_sk FROM returns_agg
    ),
    filtered_customers AS (
        SELECT cust_sk FROM union_sets
        EXCEPT
        SELECT cust_sk FROM returns_agg WHERE total_returns > 5000
    )
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COUNT(DISTINCT s.cust_sk) AS distinct_sales_customers,
    COUNT(DISTINCT r.cust_sk) AS distinct_return_customers
FROM filtered_customers fc
LEFT JOIN sales_agg s ON fc.cust_sk = s.cust_sk
LEFT JOIN returns_agg r ON fc.cust_sk = r.cust_sk
LEFT JOIN customer c ON fc.cust_sk = c.c_customer_sk
RIGHT OUTER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_location_type = 'apartment'
  AND ca.ca_suite_number LIKE 'Suite %'
  AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
GROUP BY
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(s.total_sales, 0),
    COALESCE(r.total_returns, 0)
ORDER BY total_sales DESC, total_returns ASC
LIMIT 100
