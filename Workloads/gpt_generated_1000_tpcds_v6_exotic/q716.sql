WITH filtered_returns AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_web_page_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 1
      AND wr.wr_net_loss > 0
      AND wr.wr_return_amt > 10.00
)
SELECT
    i.i_category,
    i.i_brand,
    t.t_hour,
    hd.hd_buy_potential,
    CASE WHEN fr.wr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS return_size_category,
    COUNT(*) AS return_cnt,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_return_amt_inc_tax) AS avg_return_inc_tax,
    MIN(fr.wr_return_quantity) AS min_qty,
    MAX(fr.wr_return_quantity) AS max_qty
FROM filtered_returns fr
JOIN time_dim t
    ON fr.wr_returned_time_sk = t.t_time_sk
JOIN item i
    ON fr.wr_item_sk = i.i_item_sk
JOIN customer c
    ON fr.wr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON fr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON fr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON fr.wr_web_page_sk = wp.wp_web_page_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND i.i_current_price > 100.00
  AND c.c_birth_month = 5
  AND ca.ca_state = 'CA'
  AND hd.hd_buy_potential = '1001-5000'
  AND wp.wp_type = 'product'
GROUP BY
    i.i_category,
    i.i_brand,
    t.t_hour,
    hd.hd_buy_potential,
    CASE WHEN fr.wr_return_quantity > 5 THEN 'Large' ELSE 'Small' END
ORDER BY total_return_amount DESC
LIMIT 100
