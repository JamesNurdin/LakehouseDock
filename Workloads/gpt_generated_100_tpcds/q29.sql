WITH returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim rd ON wr.wr_returned_date_sk = rd.d_date_sk
    WHERE rd.d_date >= DATE '2021-01-01' AND rd.d_date < DATE '2022-01-01'
    GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    sm.sm_type,
    cd.cd_gender,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(r.total_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(r.total_return_loss, 0)) AS total_return_loss
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_agg r
    ON ws.ws_order_number = r.wr_order_number
   AND ws.ws_item_sk = r.wr_item_sk
WHERE d.d_date >= DATE '2021-01-01' AND d.d_date < DATE '2022-01-01'
GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type, cd.cd_gender
ORDER BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type, cd.cd_gender
