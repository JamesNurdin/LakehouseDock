WITH
    intersect_items AS (
        SELECT ss_item_sk AS item_sk FROM store_sales WHERE ss_sales_price > 50
        INTERSECT
        SELECT ws_item_sk FROM web_sales WHERE ws_sales_price > 50
    ),
    avg_profit AS (
        SELECT ss_item_sk, avg(ss_net_profit) AS avg_net_profit
        FROM store_sales
        GROUP BY ss_item_sk
    )
SELECT
    i.i_item_id,
    i.i_class,
    i.i_formulation,
    ss.ss_sales_price,
    ws.ws_sales_price,
    (ss.ss_net_profit + ws.ws_net_profit) AS total_net_profit,
    RANK() OVER (PARTITION BY i.i_category ORDER BY (ss.ss_net_profit + ws.ws_net_profit) DESC) AS profit_rank,
    cc.cc_name,
    hour_part,
    ap.avg_net_profit,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    ca_ss.ca_city AS store_customer_city,
    ca_wr_refunded.ca_city AS web_return_refunded_city
FROM
    intersect_items ii
JOIN store_sales ss ON ss.ss_item_sk = ii.item_sk
JOIN web_sales ws ON ws.ws_item_sk = ii.item_sk
JOIN item i ON i.i_item_sk = ii.item_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_time_sk = t_ss.t_time_sk
LEFT JOIN (SELECT * FROM call_center TABLESAMPLE BERNOULLI (10)) cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
LEFT JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
LEFT JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
LEFT JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
LEFT JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
LEFT JOIN avg_profit ap ON ap.ss_item_sk = i.i_item_sk
CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t (hour_part)
WHERE
    i.i_class = 'shirts'
    AND i.i_formulation LIKE 'snow%'
    AND ss.ss_sales_price > 20
    AND t_ss.t_hour BETWEEN 9 AND 17
    AND cc.cc_country = 'United States'
    AND ws.ws_list_price < 200
ORDER BY profit_rank, total_net_profit DESC
LIMIT 100
