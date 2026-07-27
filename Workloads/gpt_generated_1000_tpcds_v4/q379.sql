WITH sales_aggregates AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_return_amt,
        sr.sr_store_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = cs.cs_item_sk
           AND sr.sr_returned_date_sk = cs.cs_sold_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = cs.cs_item_sk
           AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
)
SELECT
    d.d_year,
    c.c_customer_id,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    cc.cc_name AS call_center_name,
    cp.cp_catalog_number,
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name,
    wp.wp_url AS web_page_url,
    ws_site.web_name AS web_site_name,
    SUM(sa.cs_quantity) AS total_catalog_quantity,
    SUM(sa.cs_sales_price) AS total_catalog_sales,
    SUM(COALESCE(sa.cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(sa.sr_return_amt, 0)) AS total_store_returns,
    SUM(sa.ws_quantity) AS total_web_quantity,
    SUM(sa.ws_sales_price) AS total_web_sales,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sa.cs_sales_price) DESC) AS sales_rank_year,
    DENSE_RANK() OVER (ORDER BY SUM(sa.cs_sales_price) DESC) AS overall_sales_rank,
    CASE
        WHEN SUM(sa.cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(sa.cs_net_profit) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT AVG(i_sub.i_current_price) FROM item i_sub) AS avg_item_price
FROM sales_aggregates sa
JOIN date_dim d            ON d.d_date_sk = sa.cs_sold_date_sk
JOIN time_dim t            ON t.t_time_sk = sa.cs_sold_time_sk
JOIN customer c            ON c.c_customer_sk = sa.cs_bill_customer_sk
JOIN item i                ON i.i_item_sk = sa.cs_item_sk
JOIN call_center cc        ON cc.cc_call_center_sk = sa.cs_call_center_sk
JOIN catalog_page cp       ON cp.cp_catalog_page_sk = sa.cs_catalog_page_sk
JOIN ship_mode sm          ON sm.sm_ship_mode_sk = sa.cs_ship_mode_sk
JOIN warehouse w           ON w.w_warehouse_sk = sa.cs_warehouse_sk
JOIN store s               ON s.s_store_sk = sa.sr_store_sk
JOIN web_page wp           ON wp.wp_web_page_sk = sa.ws_web_page_sk
JOIN web_site ws_site      ON ws_site.web_site_sk = sa.ws_web_site_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND i.i_current_price > 20
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    d.d_year,
    c.c_customer_id,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    cc.cc_name,
    cp.cp_catalog_number,
    sm.sm_type,
    w.w_warehouse_name,
    wp.wp_url,
    ws_site.web_name
HAVING COUNT(DISTINCT sa.cs_order_number) > 5
ORDER BY total_catalog_sales DESC
LIMIT 100
