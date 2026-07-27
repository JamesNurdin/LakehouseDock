WITH sr_item AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451361 AND 2452595
      AND sr.sr_return_quantity > 1
      AND sr.sr_return_amt > 50
)
SELECT
    sr_item.i_category,
    sr_item.i_brand,
    CASE
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Female'
    END AS gender_label,
    ca.ca_state,
    COUNT(*) AS return_count,
    SUM(sr_item.sr_return_quantity + wr.wr_return_quantity) AS total_return_qty,
    SUM(sr_item.sr_return_amt + wr.wr_return_amt) AS total_return_amount,
    AVG(sr_item.sr_return_amt + wr.wr_return_amt) AS avg_return_amount,
    MAX(sr_item.sr_net_loss) AS max_net_loss
FROM sr_item
JOIN web_returns wr
    ON sr_item.sr_item_sk = wr.wr_item_sk
JOIN customer c
    ON sr_item.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sr_item.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON sr_item.sr_addr_sk = ca.ca_address_sk
WHERE wr.wr_return_quantity > 0
  AND wr.wr_reason_sk IN (23, 40)
  AND wr.wr_refunded_cash > 500
  AND ca.ca_suite_number = 'Suite 280'
  AND ca.ca_street_number = '18'
  AND cd.cd_gender = 'M'
GROUP BY
    sr_item.i_category,
    sr_item.i_brand,
    cd.cd_gender,
    ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 100
