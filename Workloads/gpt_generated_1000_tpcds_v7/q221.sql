SELECT item_id,
       hour_of_day,
       total_sales,
       transaction_count,
       channel
FROM (
    SELECT i.i_item_id AS item_id,
           td.t_hour AS hour_of_day,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           COUNT(*) AS transaction_count,
           'catalog' AS channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_county = 'Bronx County'
      AND cs.cs_sales_price > 0
    GROUP BY i.i_item_id, td.t_hour

    UNION ALL

    SELECT i.i_item_id AS item_id,
           td.t_hour AS hour_of_day,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS transaction_count,
           'web' AS channel
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'product'
      AND ws.ws_sales_price > 0
    GROUP BY i.i_item_id, td.t_hour
) AS combined
ORDER BY total_sales DESC, item_id
LIMIT 100
