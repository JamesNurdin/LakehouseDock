WITH filtered_returns AS (
    SELECT
        wr.wr_web_page_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_reason_sk,
        wr.wr_reversed_charge,
        wr.wr_order_number
    FROM tpcds.web_returns wr
    WHERE wr.wr_reason_sk IN (17, 22, 58)
      AND wr.wr_reversed_charge > 20.00
      AND wr.wr_return_quantity >= 2
      AND EXISTS (
          SELECT 1
          FROM tpcds.customer c
          WHERE c.c_customer_sk = wr.wr_refunded_customer_sk
            AND c.c_salutation = 'Mr.'
            AND c.c_current_hdemo_sk = 513
      )
)
SELECT
    wp.wp_url,
    wp.wp_type,
    COUNT(DISTINCT fr.wr_order_number) AS orders_cnt,
    SUM(fr.wr_net_loss) AS total_net_loss,
    AVG(fr.wr_return_amt) AS avg_return_amount,
    MIN(fr.wr_return_amt) AS min_return_amount,
    MAX(fr.wr_return_amt) AS max_return_amount
FROM filtered_returns fr
JOIN tpcds.web_page wp
  ON fr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_autogen_flag = 'N'
  AND wp.wp_rec_start_date >= DATE '1999-01-01'
  AND wp.wp_rec_start_date <= DATE '2001-12-31'
GROUP BY wp.wp_url, wp.wp_type
ORDER BY total_net_loss DESC
LIMIT 100
