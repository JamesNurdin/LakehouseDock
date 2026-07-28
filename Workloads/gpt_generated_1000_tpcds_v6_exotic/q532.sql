WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_promo_sk,
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        SUM(ws_net_profit) AS total_profit
    FROM tpcds.web_sales
    WHERE ws_quantity > 5
      AND ws_net_profit > 0
    GROUP BY ws_order_number, ws_item_sk, ws_promo_sk, ws_bill_cdemo_sk
),

wr_agg AS (
    SELECT
        wr_order_number,
        wr_item_sk,
        wr_reason_sk,
        wr_refunded_cdemo_sk,
        COUNT(*) AS cnt_returns,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_fee) AS total_fee,
        SUM(wr_net_loss) AS total_net_loss
    FROM tpcds.web_returns
    WHERE wr_fee > 20
      AND wr_return_amt > 0
    GROUP BY wr_order_number, wr_item_sk, wr_reason_sk, wr_refunded_cdemo_sk
)

SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.total_qty,
    ws.total_sales,
    ws.avg_discount,
    ws.total_profit,
    wr.cnt_returns,
    wr.total_return_amt,
    wr.total_fee,
    wr.total_net_loss,
    p.p_promo_name,
    p.p_channel_dmail,
    r.r_reason_desc,
    cd.cd_gender,
    cd.cd_education_status,
    RANK() OVER (PARTITION BY ws.ws_promo_sk ORDER BY ws.total_profit DESC) AS profit_rank_by_promo,
    SUM(wr.total_fee) OVER (PARTITION BY ws.ws_promo_sk ORDER BY ws.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_fee_by_promo
FROM ws_agg ws
JOIN wr_agg wr
  ON ws.ws_order_number = wr.wr_order_number
 AND ws.ws_item_sk = wr.wr_item_sk
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE p.p_channel_dmail = 'Y'
  AND r.r_reason_id LIKE 'AAAAAAA%'
  AND cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
  AND ws.total_sales > 1000
ORDER BY ws.total_profit DESC, ws.ws_order_number
LIMIT 100
