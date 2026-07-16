WITH page_returns AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_reversed_charge,
        wr.wr_account_credit,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type IS NOT NULL
)
SELECT
    wp_type,
    COUNT(*) AS total_returns,
    SUM(wr_return_quantity) AS total_return_quantity,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_return_tax) AS total_return_tax,
    SUM(wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr_net_loss) AS total_net_loss,
    (SUM(wr_net_loss) * 100.0) / SUM(SUM(wr_net_loss)) OVER () AS net_loss_pct,
    AVG(wr_return_amt) AS avg_return_amount
FROM page_returns
GROUP BY wp_type
ORDER BY total_net_loss DESC
LIMIT 10
