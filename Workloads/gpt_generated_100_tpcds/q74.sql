WITH store_agg AS (
    SELECT
        sr.sr_customer_sk AS c_customer_sk,
        COUNT(*) AS store_return_cnt,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
web_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS c_customer_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk
),
web_page_agg AS (
    SELECT
        wp.wp_customer_sk AS c_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_cnt,
        COUNT(DISTINCT wp.wp_url) AS distinct_urls_cnt
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(sa.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(sa.store_return_amt, 0) AS store_return_amt,
    COALESCE(sa.store_net_loss, 0) AS store_net_loss,
    COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(wa.web_return_amt, 0) AS web_return_amt,
    COALESCE(wa.web_net_loss, 0) AS web_net_loss,
    COALESCE(wpa.distinct_pages_cnt, 0) AS distinct_pages_cnt,
    COALESCE(wpa.distinct_urls_cnt, 0) AS distinct_urls_cnt,
    (COALESCE(sa.store_return_amt, 0) + COALESCE(wa.web_return_amt, 0)) /
        NULLIF(COALESCE(sa.store_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0), 0) AS avg_return_amt,
    (COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    RANK() OVER (ORDER BY (COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC) AS net_loss_rank
FROM customer c
LEFT JOIN store_agg sa ON c.c_customer_sk = sa.c_customer_sk
LEFT JOIN web_agg wa ON c.c_customer_sk = wa.c_customer_sk
LEFT JOIN web_page_agg wpa ON c.c_customer_sk = wpa.c_customer_sk
WHERE (COALESCE(sa.store_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0)) > 0
ORDER BY total_net_loss DESC
LIMIT 50
