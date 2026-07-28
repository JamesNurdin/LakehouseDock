WITH joined AS (
    SELECT
        cc.cc_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        hd_bill.hd_buy_potential,
        ws.ws_net_profit,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_return.d_date_sk
    WHERE d_sold.d_year = 2001
      AND hd_bill.hd_income_band_sk BETWEEN 10 AND 16
      AND cc.cc_state = 'CA'
      AND wr.wr_return_amt_inc_tax > 100
      AND ws.ws_net_profit > 0
),
aggregated AS (
    SELECT
        cc_name,
        d_year,
        d_month_seq,
        hd_buy_potential,
        SUM(ws_net_profit) AS total_profit,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS order_count
    FROM joined
    GROUP BY cc_name, d_year, d_month_seq, hd_buy_potential
)
SELECT
    cc_name,
    d_year,
    d_month_seq,
    hd_buy_potential,
    total_profit,
    total_return_amount,
    order_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank ASC, total_profit DESC
LIMIT 100
