WITH page_returns AS (
    SELECT
        wr.wr_web_page_sk AS web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk
)
SELECT
    DENSE_RANK() OVER (ORDER BY pr.total_return_amt DESC) AS amount_rank,
    ROW_NUMBER() OVER (ORDER BY pr.total_net_loss DESC) AS loss_rank,
    wp.wp_web_page_id,
    wp.wp_url,
    wp.wp_type,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    pr.total_return_amt,
    pr.total_net_loss,
    pr.avg_return_amt,
    pr.return_cnt,
    CASE WHEN pr.total_net_loss > 1000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category,
    ROUND(pr.total_net_loss / NULLIF(pr.total_return_amt, 0), 4) AS loss_to_return_ratio
FROM page_returns pr
JOIN web_page wp
    ON pr.web_page_sk = wp.wp_web_page_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
ORDER BY amount_rank
LIMIT 10
