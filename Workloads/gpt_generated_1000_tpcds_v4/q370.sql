WITH joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        w.w_warehouse_name,
        w.w_state,
        ss.ss_net_paid               AS store_net_paid,
        ws.ws_net_paid               AS web_net_paid,
        cr.cr_net_loss               AS return_net_loss,
        r.r_reason_desc              AS reason_desc
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    w_warehouse_name,
    SUM(store_net_paid)                     AS total_store_sales,
    SUM(web_net_paid)                       AS total_web_sales,
    SUM(return_net_loss)                    AS total_return_loss,
    CASE WHEN SUM(store_net_paid) > 20000 THEN 'High' ELSE 'Low' END AS sales_category,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(store_net_paid) DESC) AS store_sales_rank_year
FROM joined_data
WHERE d_year = 2002
  AND w_state = 'CA'
  AND reason_desc LIKE '%not working%'
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    w_warehouse_name
ORDER BY
    total_store_sales DESC,
    store_sales_rank_year
LIMIT 100
