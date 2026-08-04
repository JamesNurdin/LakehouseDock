WITH page_not_monthly AS (
    SELECT cs_catalog_page_sk
    FROM catalog_sales
    EXCEPT
    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_type = 'monthly'
),
sales_filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_item_sk,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_profit > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2)
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND cs.cs_catalog_page_sk IN (SELECT cs_catalog_page_sk FROM page_not_monthly)
)
SELECT
    dept,
    state,
    total_sales,
    avg_profit,
    distinct_orders,
    CASE
        WHEN total_profit > 100000 THEN 'HIGH'
        WHEN total_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    total_returns,
    return_count
FROM (
    SELECT
        cp.cp_department AS dept,
        ca.ca_state AS state,
        SUM(sf.cs_ext_sales_price) AS total_sales,
        AVG(sf.cs_net_profit) AS avg_profit,
        SUM(sf.cs_net_profit) AS total_profit,
        COUNT(DISTINCT sf.cs_order_number) AS distinct_orders,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM sales_filtered sf
    JOIN catalog_page cp
        ON sf.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca
        ON sf.cs_bill_addr_sk = ca.ca_address_sk
    RIGHT JOIN store_returns sr
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE cp.cp_type IN ('bi-annual', 'quarterly')
      AND ca.ca_state = 'CA'
      AND ca.ca_location_type = 'apartment'
    GROUP BY cp.cp_department, ca.ca_state
) t
ORDER BY total_sales DESC
LIMIT 100
