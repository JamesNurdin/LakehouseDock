/*
Goal: Analyze web return performance by reason and customer gender, comparing return amounts to the overall average, and summarizing fees, reversed charges and related sales profit.
*/
WITH sales_demo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ext_ship_cost,
        ws.ws_quantity,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_education_status
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_ext_ship_cost > 500
      AND ws.ws_quantity > 1
)
SELECT
    r.r_reason_desc,
    sd.cd_gender,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(CASE WHEN wr.wr_reversed_charge > 50 THEN wr.wr_reversed_charge ELSE 0 END) AS reversed_charge_over_50,
    AVG(sd.ws_net_profit) AS avg_net_profit,
    CASE
        WHEN SUM(wr.wr_return_amt) > (
            SELECT AVG(wr2.wr_return_amt) FROM tpcds.web_returns wr2
        ) THEN 'Above Avg Return'
        ELSE 'Below Avg Return'
    END AS return_amount_category
FROM tpcds.web_returns wr
JOIN sales_demo sd
    ON wr.wr_order_number = sd.ws_order_number
   AND wr.wr_item_sk = sd.ws_item_sk
JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
WHERE wr.wr_returning_cdemo_sk = 1104998
  AND wr.wr_fee BETWEEN 10 AND 30
  AND r.r_reason_desc LIKE '%gift%'
  AND cd_ret.cd_credit_rating = 'A'
  AND wr.wr_return_amt > 100
GROUP BY r.r_reason_desc, sd.cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
