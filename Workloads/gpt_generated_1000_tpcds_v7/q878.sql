/*
Goal: Analyze the combined impact of catalog and web returns on sales by brand and hour of the day, focusing on high‑fee returns, specific brands, and male customers.
*/
SELECT
    i.i_brand,
    td.t_hour,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_order_cnt,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM
    tpcds.catalog_returns cr
JOIN
    tpcds.time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
JOIN
    tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
JOIN
    tpcds.web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
JOIN
    tpcds.web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
JOIN
    tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE
    td.t_hour = 14
    AND i.i_brand = 'namelessunivamalg #11'
    AND i.i_manager_id IN (34, 6)
    AND cr.cr_fee > 50.00
    AND cr.cr_store_credit BETWEEN 0 AND 500
    AND ws.ws_list_price > 100.00
    AND wr.wr_return_quantity = 1
    AND cd.cd_gender = 'M'
GROUP BY
    i.i_brand,
    td.t_hour
ORDER BY
    total_sales_amount DESC
LIMIT 100
