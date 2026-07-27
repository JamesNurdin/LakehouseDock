WITH filtered_sales AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_ship_addr_sk,
        cs.cs_net_profit,
        cs.cs_ext_ship_cost,
        cs.cs_list_price
    FROM catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 500
      AND cs.cs_list_price > (SELECT avg(cs2.cs_list_price) FROM catalog_sales cs2)
      AND cs.cs_list_price BETWEEN 50 AND 150
)
SELECT
    cp.cp_department,
    cp.cp_catalog_page_id,
    ca.ca_state,
    SUM(fs.cs_net_profit) AS total_net_profit,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(fs.cs_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca
    ON fs.cs_ship_addr_sk = ca.ca_address_sk
WHERE cp.cp_catalog_number IN (5, 12, 20)
  AND ca.ca_country = 'United States'
  AND ca.ca_street_type = 'Blvd'
GROUP BY cp.cp_department, cp.cp_catalog_page_id, ca.ca_state
ORDER BY profit_rank, total_net_profit DESC
LIMIT 100
