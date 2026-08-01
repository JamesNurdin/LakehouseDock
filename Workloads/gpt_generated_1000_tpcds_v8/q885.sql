WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)  -- Approx. 10% random sample
    WHERE ws_ext_sales_price > 500
      AND ws_quantity BETWEEN 1 AND 10
      AND ws_ship_mode_sk IN (1, 2, 3)
      AND ws_ship_customer_sk = 6685171
      AND ws_promo_sk IS NOT NULL
),

address_exceptions AS (
    SELECT ca_address_sk
    FROM customer_address
    EXCEPT
    SELECT ws_bill_addr_sk
    FROM sampled_ws
),

ws_with_array AS (
    SELECT
        ws_order_number,
        ws_quantity,
        ws_list_price,
        ARRAY[ws_quantity, ws_list_price] AS qty_price_arr,
        ws_bill_addr_sk,
        ws_ship_addr_sk,
        ws_ext_sales_price,
        ws_net_profit
    FROM sampled_ws
),

unnested AS (
    SELECT
        ws_order_number,
        ws_bill_addr_sk,
        ws_ship_addr_sk,
        element AS metric_value,
        CASE WHEN element = ws_quantity THEN 'quantity' ELSE 'list_price' END AS metric_type
    FROM ws_with_array
    CROSS JOIN UNNEST(qty_price_arr) AS t(element)
),

joined AS (
    SELECT
        ca.ca_state                AS ca_state,
        ca.ca_location_type        AS ca_location_type,
        ca.ca_gmt_offset           AS ca_gmt_offset,
        un.metric_type             AS metric_type,
        un.metric_value            AS metric_value,
        ws.ws_ext_sales_price      AS ws_ext_sales_price,
        ws.ws_net_profit           AS ws_net_profit,
        ws.ws_order_number         AS ws_order_number
    FROM sampled_ws ws
    FULL OUTER JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN unnested un
        ON ws.ws_order_number = un.ws_order_number
    WHERE ca.ca_country = 'United States' OR ca.ca_country IS NULL
)

SELECT
    ca_state,
    ca_location_type,
    CASE WHEN ca_gmt_offset >= 0 THEN 'EAST_COAST' ELSE 'WEST_COAST' END AS region,
    metric_type,
    COUNT(DISTINCT ws_order_number)                         AS order_cnt,
    SUM(metric_value) FILTER (WHERE metric_type = 'quantity')   AS total_quantity,
    SUM(metric_value) FILTER (WHERE metric_type = 'list_price') AS total_list_price,
    AVG(ws_ext_sales_price)                                 AS avg_sales_price,
    MIN(ws_net_profit)                                      AS min_profit,
    MAX(ws_net_profit)                                      AS max_profit,
    (SELECT COUNT(*) FROM address_exceptions)              AS missing_address_cnt
FROM joined
GROUP BY
    ca_state,
    ca_location_type,
    ca_gmt_offset,
    metric_type
HAVING COUNT(*) > 5
ORDER BY total_quantity DESC, avg_sales_price DESC
LIMIT 100
