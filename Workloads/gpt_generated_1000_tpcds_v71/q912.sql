WITH filtered_returns AS (
    SELECT
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_item_sk,
        wr_refunded_customer_sk,
        wr_refunded_cdemo_sk,
        wr_refunded_hdemo_sk,
        wr_refunded_addr_sk,
        wr_returning_customer_sk,
        wr_returning_cdemo_sk,
        wr_returning_hdemo_sk,
        wr_returning_addr_sk,
        wr_web_page_sk,
        wr_reason_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        wr_return_amt_inc_tax,
        wr_fee,
        wr_return_ship_cost,
        wr_refunded_cash,
        wr_reversed_charge,
        wr_account_credit,
        wr_net_loss
    FROM web_returns
    WHERE wr_return_ship_cost > 150
      AND wr_fee < 50
      AND wr_return_amt BETWEEN 200 AND 5000
      AND wr_return_quantity >= 2
      AND wr_returned_time_sk IN (101, 202, 303)
      AND wr_web_page_sk IN (10, 20, 30)
)
SELECT
    td.t_hour,
    td.t_sub_shift,
    wp.wp_type,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(fr.wr_return_ship_cost) AS min_ship_cost,
    MAX(fr.wr_fee) AS max_fee
FROM filtered_returns fr
JOIN time_dim td ON fr.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp ON fr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_autogen_flag = 'N'
  AND wp.wp_max_ad_count <= 2
  AND wp.wp_image_count >= 3
GROUP BY td.t_hour, td.t_sub_shift, wp.wp_type

UNION ALL

SELECT
    td.t_hour,
    td.t_sub_shift,
    wp.wp_type,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(wr.wr_return_ship_cost) AS min_ship_cost,
    MAX(wr.wr_fee) AS max_fee
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wr.wr_return_ship_cost < 200
  AND wr.wr_fee > 30
  AND wr.wr_return_quantity = 1
  AND td.t_sub_shift = 'morning'
  AND wp.wp_autogen_flag = 'Y'
  AND wp.wp_image_count BETWEEN 1 AND 5
GROUP BY td.t_hour, td.t_sub_shift, wp.wp_type

ORDER BY total_return_amount DESC
LIMIT 100
