WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        'Catalog' AS sales_channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 100
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 10000
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        'Web' AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 18 AND 23
      AND i.i_current_price > 100
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(ws.ws_net_paid_inc_ship_tax) > 10000
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
