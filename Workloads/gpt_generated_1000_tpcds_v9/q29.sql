WITH agg_store_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid)        AS total_store_net_paid,
        SUM(ss.ss_quantity)        AS total_store_quantity,
        COUNT(*)                    AS store_txn_count
    FROM store_sales ss
    WHERE ss.ss_net_paid > 0
      AND ss.ss_quantity >= 1
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk, ss.ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    web_site.web_name                     AS web_site_name,
    cp.cp_department,
    td_store.t_hour                        AS sale_hour,
    td_store.t_meal_time,
    agg.total_store_net_paid,
    agg.total_store_quantity,
    SUM(ws.ws_ext_sales_price)            AS total_web_sales,
    SUM(cr.cr_return_amount)              AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number)    AS distinct_web_orders,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY agg.total_store_net_paid DESC) AS store_rank,
    (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = web_site.web_site_sk
          AND ws2.ws_sold_date_sk = agg.ss_sold_date_sk
    )                                      AS avg_web_sales_for_site_date
FROM agg_store_sales agg
JOIN store s
    ON agg.ss_store_sk = s.s_store_sk
JOIN time_dim td_store
    ON agg.ss_sold_time_sk = td_store.t_time_sk
JOIN customer c
    ON agg.ss_customer_sk = c.c_customer_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN time_dim td_web
    ON ws.ws_sold_time_sk = td_web.t_time_sk
JOIN web_site web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN time_dim td_return
    ON cr.cr_returned_time_sk = td_return.t_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    c.c_birth_year = 1985
    AND s.s_state = 'CA'
    AND web_site.web_state = 'CA'
    AND td_store.t_hour BETWEEN 9 AND 17
    AND cp.cp_department = 'DEPARTMENT'
    AND ws.ws_list_price > 50
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
          AND cr2.cr_returned_date_sk = agg.ss_sold_date_sk
    )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    web_site.web_name,
    cp.cp_department,
    td_store.t_hour,
    td_store.t_meal_time,
    agg.total_store_net_paid,
    agg.total_store_quantity,
    s.s_store_id,
    web_site.web_site_sk,
    agg.ss_sold_date_sk
ORDER BY
    agg.total_store_net_paid DESC,
    total_web_sales DESC
LIMIT 100
