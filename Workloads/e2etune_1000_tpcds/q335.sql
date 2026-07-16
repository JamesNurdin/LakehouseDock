WITH store_agg AS (
    SELECT sr.sr_customer_sk AS cust_sk,
           SUM(sr.sr_net_loss) AS store_net_loss,
           SUM(sr.sr_return_quantity) AS store_return_qty,
           COUNT(*) AS store_return_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450905 AND 2451087
    GROUP BY sr.sr_customer_sk
),
web_agg AS (
    SELECT wr.wr_refunded_customer_sk AS cust_sk,
           SUM(wr.wr_net_loss) AS web_net_loss,
           SUM(wr.wr_return_quantity) AS web_return_qty,
           COUNT(*) AS web_return_cnt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450905 AND 2451087
    GROUP BY wr.wr_refunded_customer_sk
),
web_page_agg AS (
    SELECT wp.wp_customer_sk AS cust_sk,
           AVG(wp.wp_link_count) AS avg_link_count,
           COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages
    FROM web_page wp
    JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450905 AND 2451087
    GROUP BY wp.wp_customer_sk
)
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
       COALESCE(sa.store_return_qty, 0) + COALESCE(wa.web_return_qty, 0) AS total_return_quantity,
       COALESCE(sa.store_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0) AS total_return_cnt,
       COALESCE(wpa.avg_link_count, 0) AS avg_page_link_count,
       COALESCE(wpa.distinct_pages, 0) AS distinct_page_cnt,
       RANK() OVER (ORDER BY (COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC) AS loss_rank
FROM customer c
LEFT JOIN store_agg sa ON sa.cust_sk = c.c_customer_sk
LEFT JOIN web_agg wa ON wa.cust_sk = c.c_customer_sk
LEFT JOIN web_page_agg wpa ON wpa.cust_sk = c.c_customer_sk
WHERE (COALESCE(sa.store_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0)) >= 2
ORDER BY total_net_loss DESC
LIMIT 100
