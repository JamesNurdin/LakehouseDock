WITH joined AS (
    SELECT
        cp.cp_department,
        i.i_brand,
        ca.ca_state,
        CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Affordable' END AS price_category,
        td_ss.t_hour,
        ss.ss_net_paid,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN time_dim td_ss
        ON ss.ss_sold_time_sk = td_ss.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN customer_address ca
        ON ca.ca_address_sk = wr.wr_refunded_addr_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    WHERE cp.cp_department = 'Sports'
      AND i.i_category = 'Electronics'
      AND ca.ca_state = 'CA'
      AND td_ss.t_hour BETWEEN 9 AND 17
      AND td_sr.t_hour BETWEEN 9 AND 17
      AND td_wr.t_hour BETWEEN 9 AND 17
)
SELECT
    cp_department,
    i_brand,
    ca_state,
    price_category,
    t_hour,
    SUM(ss_net_paid)               AS total_sales,
    SUM(cr_return_amount)           AS total_catalog_returns,
    SUM(sr_return_amt)              AS total_store_returns,
    SUM(wr_return_amt)              AS total_web_returns,
    COUNT(DISTINCT ss_ticket_number) AS distinct_sales_orders,
    RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM joined
GROUP BY
    cp_department,
    i_brand,
    ca_state,
    price_category,
    t_hour
ORDER BY total_sales DESC
LIMIT 100
