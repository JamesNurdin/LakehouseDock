WITH distinct_pages AS (
        SELECT DISTINCT cp_catalog_page_sk, cp_department
        FROM catalog_page
        WHERE cp_department = 'Electronics'
    ),
    agg_sales AS (
        SELECT
            cs_item_sk,
            cs_order_number,
            cs_catalog_page_sk,
            cs_ship_mode_sk,
            cs_sold_time_sk,
            SUM(cs_net_paid) AS total_net_paid,
            COUNT(*) AS sales_cnt
        FROM catalog_sales
        WHERE cs_quantity > 2
        GROUP BY cs_item_sk, cs_order_number, cs_catalog_page_sk, cs_ship_mode_sk, cs_sold_time_sk
    )
SELECT
    dp.cp_department AS department,
    sm.sm_carrier AS carrier,
    td.t_hour AS hour_of_day,
    COUNT(DISTINCT a.cs_order_number) AS distinct_orders,
    SUM(a.total_net_paid) AS total_sales_net,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    AVG(a.sales_cnt) AS avg_sales_per_item
FROM time_dim td
JOIN agg_sales a
    ON a.cs_sold_time_sk = td.t_time_sk
JOIN distinct_pages dp
    ON dp.cp_catalog_page_sk = a.cs_catalog_page_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = a.cs_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
    AND cr.cr_order_number = a.cs_order_number
    AND cr.cr_item_sk = a.cs_item_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = td.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE td.t_hour = 14
  AND sm.sm_carrier = 'UPS'
  AND wp.wp_link_count > 20
GROUP BY dp.cp_department, sm.sm_carrier, td.t_hour
HAVING SUM(a.total_net_paid) > 10000
ORDER BY total_sales_net DESC
LIMIT 100
