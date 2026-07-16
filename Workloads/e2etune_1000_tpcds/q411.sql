WITH returns_agg AS (
    SELECT
        wr_web_page_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT wr_returning_customer_sk) AS distinct_customers
    FROM web_returns
    WHERE wr_return_amt_inc_tax > 0
    GROUP BY wr_web_page_sk
),
page_details AS (
    SELECT
        wp_web_page_sk,
        wp_type,
        wp_url,
        wp_image_count,
        wp_char_count,
        wp_link_count
    FROM web_page
    WHERE wp_type IS NOT NULL
)
SELECT
    pd.wp_type,
    pd.wp_url,
    ra.return_cnt,
    ra.total_return_amt_inc_tax,
    ra.total_net_loss,
    ra.avg_return_qty,
    ra.distinct_customers,
    RANK() OVER (PARTITION BY pd.wp_type ORDER BY ra.total_net_loss DESC) AS net_loss_rank
FROM returns_agg ra
JOIN page_details pd
    ON ra.wr_web_page_sk = pd.wp_web_page_sk
WHERE ra.total_return_amt_inc_tax > 1000
ORDER BY ra.total_net_loss DESC
LIMIT 50
