WITH combined_returns AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        cr_return_quantity AS return_quantity,
        cr_net_loss AS net_loss,
        'catalog' AS source
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_refunded_customer_sk,
        wr_return_quantity,
        wr_net_loss,
        'web' AS source
    FROM web_returns
),
customer_agg AS (
    SELECT
        cr.customer_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.net_loss) AS total_net_loss,
        SUM(CASE WHEN cr.source = 'catalog' THEN cr.net_loss ELSE 0 END) AS catalog_net_loss,
        SUM(CASE WHEN cr.source = 'web' THEN cr.net_loss ELSE 0 END) AS web_net_loss
    FROM combined_returns cr
    GROUP BY cr.customer_sk
),
ranked_customers AS (
    SELECT
        ca.*,
        RANK() OVER (ORDER BY ca.total_net_loss DESC) AS rank
    FROM customer_agg ca
)
SELECT
    rc.rank,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rc.total_return_quantity,
    rc.total_net_loss,
    rc.catalog_net_loss,
    rc.web_net_loss,
    CASE WHEN rc.total_net_loss > 0 THEN 'Gain' ELSE 'Loss' END AS net_loss_indicator
FROM ranked_customers rc
JOIN customer c
    ON rc.customer_sk = c.c_customer_sk
WHERE rc.rank <= 5
ORDER BY rc.rank
