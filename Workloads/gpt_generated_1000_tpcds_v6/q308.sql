SELECT
    cd.cd_education_status AS education_status,
    'Billing' AS source_type,
    CASE
        WHEN sum(ws.ws_net_profit) > 0 THEN 'Positive'
        WHEN sum(ws.ws_net_profit) < 0 THEN 'Negative'
        ELSE 'Zero'
    END AS profit_category,
    sum(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE ws.ws_wholesale_cost BETWEEN 10 AND 80
  AND ws.ws_ext_ship_cost > 100
  AND cd.cd_dep_count <= 5
GROUP BY cd.cd_education_status

UNION ALL

SELECT
    cd.cd_education_status AS education_status,
    'Shipping' AS source_type,
    CASE
        WHEN sum(ws.ws_net_profit) > 0 THEN 'Positive'
        WHEN sum(ws.ws_net_profit) < 0 THEN 'Negative'
        ELSE 'Zero'
    END AS profit_category,
    sum(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN customer_demographics cd
    ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
WHERE ws.ws_wholesale_cost BETWEEN 10 AND 80
  AND ws.ws_ext_ship_cost > 100
  AND cd.cd_dep_count <= 5
GROUP BY cd.cd_education_status
ORDER BY education_status, source_type
