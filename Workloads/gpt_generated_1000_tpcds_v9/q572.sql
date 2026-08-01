SELECT
    i.i_brand,
    REGEXP_EXTRACT(i.i_formulation, '(\\w+)$', 1) AS formulation_suffix,
    CONCAT(i.i_brand, '-', REGEXP_EXTRACT(i.i_formulation, '(\\w+)$', 1)) AS brand_formulation_code,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    CASE WHEN SUM(ws.ws_net_profit) > 1000000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(ws.ws_net_profit) / (SELECT SUM(ws2.ws_net_profit) FROM web_sales ws2) AS profit_share,
    MIN(SUBSTR(i.i_item_desc, 1, 15)) AS example_desc
FROM
    web_sales ws
JOIN
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN
    time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE
    REGEXP_LIKE(i.i_formulation, '^\\d{5}')
    AND i.i_formulation LIKE '%olive%'
    AND t.t_hour BETWEEN 9 AND 17
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_order_number = ws.ws_order_number
    )
GROUP BY
    i.i_brand,
    REGEXP_EXTRACT(i.i_formulation, '(\\w+)$', 1)
ORDER BY
    total_net_profit DESC
LIMIT 100
