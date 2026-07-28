WITH store_ret AS (
    SELECT DISTINCT
        sr.sr_returned_date_sk AS return_date_sk,
        'Store' AS source,
        st.s_store_name AS location_name,
        i.i_item_id AS item_id,
        sr.sr_net_loss,
        CASE WHEN sr.sr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_net_loss IS NOT NULL
),
web_ret AS (
    SELECT DISTINCT
        wr.wr_returned_date_sk AS return_date_sk,
        'Web' AS source,
        wp.wp_url AS location_name,
        i.i_item_id AS item_id,
        wr.wr_net_loss,
        CASE WHEN wr.wr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_net_loss IS NOT NULL
)
SELECT * FROM store_ret
UNION ALL
SELECT * FROM web_ret
ORDER BY return_date_sk DESC
LIMIT 100
