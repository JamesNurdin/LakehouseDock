WITH ss AS (
    SELECT
        ss_ticket_number,
        ss_sold_date_sk,
        ss_item_sk,
        ss_store_sk,
        ss_customer_sk,
        ss_quantity,
        ss_sales_price,
        ss_ext_sales_price,
        ss_net_paid,
        ss_net_profit
    FROM store_sales
),
sr AS (
    SELECT
        sr_ticket_number,
        sr_return_quantity,
        sr_return_amt,
        sr_net_loss,
        sr_item_sk,
        sr_store_sk,
        sr_customer_sk
    FROM store_returns
)
SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(cr.cr_fee) AS total_catalog_fee,
    CASE WHEN SUM(cr.cr_fee) > 1000 THEN 'HIGH' ELSE 'LOW' END AS fee_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_cnt,
    GROUPING(s.s_store_name) AS grp_store,
    GROUPING(i.i_category) AS grp_category
FROM ss
JOIN sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store s_sr ON sr.sr_store_sk = s_sr.s_store_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN customer c_cr ON cr.cr_refunded_customer_sk = c_cr.c_customer_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN customer c_wr ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
GROUP BY GROUPING SETS (
    (s.s_store_name, i.i_category),
    (s.s_store_name),
    (i.i_category),
    ()
)
ORDER BY total_sales_amount DESC
LIMIT 100
