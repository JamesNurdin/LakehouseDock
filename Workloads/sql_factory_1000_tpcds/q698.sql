WITH shipping_data AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        cs.cs_ext_ship_cost AS ship_cost,
        cs.cs_net_profit AS net_profit,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN date_dim d
      ON cs.cs_ship_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        ss.ss_ext_sales_price * 0.05 AS ship_cost,
        ss.ss_net_profit AS net_profit,
        'Store' AS channel
    FROM store_sales ss
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
)
SELECT
    state,
    year,
    channel,
    AVG(ship_cost) AS avg_ship_cost,
    AVG(net_profit) AS avg_net_profit,
    CASE
        WHEN AVG(ship_cost) > 100 THEN 'High Cost'
        WHEN AVG(ship_cost) > 40 THEN 'Medium Cost'
        ELSE 'Low Cost'
    END AS cost_category,
    DENSE_RANK() OVER (PARTITION BY channel ORDER BY AVG(ship_cost) DESC) AS ship_cost_rank
FROM shipping_data
WHERE year = 2022
GROUP BY state, year, channel
ORDER BY channel, ship_cost_rank
