WITH page_returns AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_image_count,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_return_ship_cost) AS total_ship_cost,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        SUM(wr.wr_reversed_charge) AS total_reversed_charge,
        SUM(wr.wr_account_credit) AS total_account_credit,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_image_count
)
SELECT
    wp_web_page_sk,
    wp_url,
    wp_type,
    wp_char_count,
    wp_link_count,
    wp_image_count,
    total_return_quantity,
    total_return_amt,
    total_return_amt / NULLIF(total_return_quantity, 0) AS avg_return_amt_per_item,
    total_net_loss,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_amt_rank
FROM page_returns
WHERE total_return_quantity > 0
ORDER BY total_return_amt DESC
LIMIT 100
