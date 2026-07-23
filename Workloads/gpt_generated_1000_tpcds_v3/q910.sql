WITH base_sales AS (
    SELECT
        sm.sm_code,
        sm.sm_contract,
        COUNT(*) AS orders,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE d_sold.d_year = 2020
      AND regexp_like(sm.sm_contract, '^.{2}[0-9]')
      AND ca.ca_city LIKE 'San%'
      AND EXISTS (
          SELECT 1 FROM catalog_sales cs2
          WHERE cs2.cs_ship_mode_sk = cs.cs_ship_mode_sk
            AND cs2.cs_ship_date_sk = cs.cs_ship_date_sk
            AND cs2.cs_ext_discount_amt > 50
      )
    GROUP BY sm.sm_code, sm.sm_contract
    HAVING COUNT(*) > 10
)
SELECT
    CONCAT(base_sales.sm_code, '-', base_sales.sm_contract) AS mode_contract,
    SUBSTRING(base_sales.sm_code, 1, 2) AS sm_code_prefix,
    base_sales.orders,
    base_sales.total_net_paid,
    base_sales.avg_net_profit,
    CASE WHEN base_sales.total_net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    ROUND(base_sales.total_net_profit / (
        SELECT SUM(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2020
    ), 4) AS profit_share_of_year,
    (SELECT MAX(d3.d_month_seq) FROM date_dim d3 WHERE d3.d_year = 2020) AS max_month_seq_2020
FROM base_sales
ORDER BY base_sales.total_net_paid DESC
LIMIT 100
