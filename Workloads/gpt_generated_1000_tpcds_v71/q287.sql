WITH aggregated AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_catalog_sales,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_sales
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 1000
      AND cs.cs_ext_ship_cost BETWEEN 100 AND 5000
      AND ca.ca_zip IN ('51387','63951','68252','79584','75124')
      AND ws.ws_list_price > 50
      AND ws.ws_ext_ship_cost < 2000
    GROUP BY ca.ca_state, ca.ca_city
)
SELECT
    a.ca_state AS state,
    a.ca_city AS city,
    a.total_catalog_sales,
    a.total_web_sales,
    (a.total_catalog_sales + a.total_web_sales) AS combined_sales,
    RANK() OVER (PARTITION BY a.ca_state ORDER BY (a.total_catalog_sales + a.total_web_sales) DESC) AS city_rank,
    AVG(a.total_catalog_sales + a.total_web_sales) OVER (
        PARTITION BY a.ca_state
        ORDER BY a.total_catalog_sales + a.total_web_sales
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS moving_avg_sales,
    (
        SELECT AVG(t.combined_sales)
        FROM (
            SELECT (total_catalog_sales + total_web_sales) AS combined_sales
            FROM aggregated
        ) t
    ) AS overall_avg_sales
FROM aggregated a
WHERE (a.total_catalog_sales + a.total_web_sales) > (
        SELECT AVG(t.combined_sales)
        FROM (
            SELECT (total_catalog_sales + total_web_sales) AS combined_sales
            FROM aggregated
        ) t
    )
ORDER BY a.ca_state, city_rank
LIMIT 100
