WITH avg_price AS (
    SELECT AVG(i2.i_current_price) AS avg_price
    FROM item i2
)
SELECT
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    cd_refunded.cd_gender AS refunded_gender,
    d_ret.d_year AS return_year,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_net_loss) AS total_net_loss,
    (
        SELECT AVG(wr2.wr_return_amt_inc_tax)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
    ) AS avg_item_return_amt,
    (SELECT avg_price FROM avg_price) AS overall_avg_item_price
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_ret2
    ON wr.wr_returned_date_sk = d_ret2.d_date_sk
JOIN date_dim d_ret3
    ON wr.wr_returned_date_sk = d_ret3.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret3.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN call_center cc2
    ON cc2.cc_open_date_sk = d_ret2.d_date_sk
JOIN date_dim d_extra
    ON cc2.cc_closed_date_sk = d_extra.d_date_sk
WHERE d_ret.d_current_quarter = 'Y'
  AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
  AND cd_refunded.cd_education_status = 'Advanced Degree'
GROUP BY
    cc.cc_name,
    cc.cc_state,
    i.i_category,
    i.i_brand,
    cd_refunded.cd_gender,
    d_ret.d_year,
    i.i_item_sk
ORDER BY total_return_amount DESC
LIMIT 100
