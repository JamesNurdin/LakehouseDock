WITH
    cr AS (
        SELECT *
        FROM catalog_returns
    ),
    t_cr AS (
        SELECT *
        FROM time_dim
    ),
    cust_refund AS (
        SELECT *
        FROM customer
    ),
    addr_refund AS (
        SELECT *
        FROM customer_address
    ),
    cust_returning AS (
        SELECT *
        FROM customer
    ),
    addr_returning AS (
        SELECT *
        FROM customer_address
    ),
    cp AS (
        SELECT *
        FROM catalog_page
    ),
    wh_cat AS (
        SELECT *
        FROM warehouse
    ),
    r_cat AS (
        SELECT *
        FROM reason
    ),
    ss AS (
        SELECT *
        FROM store_sales
    ),
    t_ss AS (
        SELECT *
        FROM time_dim
    ),
    st AS (
        SELECT *
        FROM store
    ),
    sr AS (
        SELECT *
        FROM store_returns
    ),
    t_sr AS (
        SELECT *
        FROM time_dim
    ),
    r_store AS (
        SELECT *
        FROM reason
    ),
    inv AS (
        SELECT *
        FROM inventory
    ),
    ws AS (
        SELECT *
        FROM web_sales
    ),
    t_ws AS (
        SELECT *
        FROM time_dim
    ),
    wp AS (
        SELECT *
        FROM web_page
    ),
    wh_web AS (
        SELECT *
        FROM warehouse
    ),
    wr AS (
        SELECT *
        FROM web_returns
    ),
    t_wr AS (
        SELECT *
        FROM time_dim
    ),
    r_web AS (
        SELECT *
        FROM reason
    )
SELECT
    st.s_store_name,
    wh_cat.w_warehouse_name,
    r_cat.r_reason_desc        AS catalog_return_reason,
    r_store.r_reason_desc      AS store_return_reason,
    r_web.r_reason_desc        AS web_return_reason,
    cp.cp_catalog_number,
    SUM(cr.cr_net_loss)        AS total_catalog_net_loss,
    SUM(sr.sr_net_loss)        AS total_store_net_loss,
    SUM(wr.wr_net_loss)        AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number)  AS web_return_cnt
FROM cr
INNER JOIN t_cr      ON cr.cr_returned_time_sk = t_cr.t_time_sk
INNER JOIN cust_refund   ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
INNER JOIN addr_refund   ON cr.cr_refunded_addr_sk = addr_refund.ca_address_sk
INNER JOIN cust_returning ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
INNER JOIN addr_returning ON cr.cr_returning_addr_sk = addr_returning.ca_address_sk
INNER JOIN cp        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN wh_cat    ON cr.cr_warehouse_sk = wh_cat.w_warehouse_sk
INNER JOIN r_cat     ON cr.cr_reason_sk = r_cat.r_reason_sk
-- store side
INNER JOIN ss        ON ss.ss_customer_sk = cust_refund.c_customer_sk
INNER JOIN st        ON ss.ss_store_sk = st.s_store_sk
INNER JOIN t_ss      ON ss.ss_sold_time_sk = t_ss.t_time_sk
INNER JOIN sr        ON sr.sr_ticket_number = ss.ss_ticket_number
INNER JOIN t_sr      ON sr.sr_return_time_sk = t_sr.t_time_sk
INNER JOIN r_store   ON sr.sr_reason_sk = r_store.r_reason_sk
-- inventory (ties to the same warehouse as catalog returns)
INNER JOIN inv       ON inv.inv_warehouse_sk = wh_cat.w_warehouse_sk
-- web side
INNER JOIN ws        ON ws.ws_bill_customer_sk = cust_refund.c_customer_sk
INNER JOIN t_ws      ON ws.ws_sold_time_sk = t_ws.t_time_sk
INNER JOIN wp        ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN wh_web    ON ws.ws_warehouse_sk = wh_web.w_warehouse_sk
INNER JOIN wr        ON wr.wr_order_number = ws.ws_order_number
INNER JOIN t_wr      ON wr.wr_returned_time_sk = t_wr.t_time_sk
INNER JOIN r_web     ON wr.wr_reason_sk = r_web.r_reason_sk
WHERE st.s_state = 'CA'
GROUP BY
    st.s_store_name,
    wh_cat.w_warehouse_name,
    r_cat.r_reason_desc,
    r_store.r_reason_desc,
    r_web.r_reason_desc,
    cp.cp_catalog_number
ORDER BY total_catalog_net_loss DESC
LIMIT 100
