WITH page_returns AS (
    SELECT
        p.wp_type,
        r.wr_return_quantity,
        r.wr_return_amt,
        r.wr_net_loss,
        r.wr_refunded_customer_sk,
        r.wr_returning_customer_sk
    FROM web_returns r
    JOIN web_page p
        ON r.wr_web_page_sk = p.wp_web_page_sk
)
SELECT
    pr.wp_type,
    COUNT(*) AS total_returns,
    SUM(pr.wr_return_quantity) AS total_return_quantity,
    SUM(pr.wr_return_amt) AS total_return_amount,
    SUM(pr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT pr.wr_refunded_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT pr.wr_returning_customer_sk) AS distinct_returning_customers,
    RANK() OVER (ORDER BY SUM(pr.wr_net_loss) DESC) AS net_loss_rank
FROM page_returns pr
GROUP BY pr.wp_type
ORDER BY total_net_loss DESC
LIMIT 10
