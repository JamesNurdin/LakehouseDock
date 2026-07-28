WITH sales_agg AS (
    SELECT
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_wholesale_cost > 40
      AND cs.cs_sales_price BETWEEN 30 AND 150
      AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_count <= 2
    GROUP BY ca.ca_state, cd.cd_gender
)
SELECT
    state,
    gender,
    total_sales,
    total_profit,
    avg_quantity
FROM sales_agg
WHERE total_sales > (SELECT AVG(total_sales) FROM sales_agg)
ORDER BY total_sales DESC
LIMIT 100
