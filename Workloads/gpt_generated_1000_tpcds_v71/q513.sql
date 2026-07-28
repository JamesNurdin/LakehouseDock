WITH customer_metrics AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items
    FROM tpcds.customer c
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = i.i_item_sk
       AND sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
       AND wr.wr_item_sk = i.i_item_sk
       AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE i.i_current_price > 1000
      AND ss.ss_quantity >= 50
      AND sr.sr_return_quantity > 0
      AND wp.wp_max_ad_count <= 2
      AND wr.wr_return_quantity > 0
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    total_sales,
    total_store_return_loss,
    total_web_return_loss,
    total_net_loss,
    distinct_items,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM customer_metrics
ORDER BY loss_rank
LIMIT 100
