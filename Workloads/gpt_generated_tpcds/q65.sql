/*
  Net‑profit and return analysis by product category, month and customer buy‑potential.
  The query aggregates web sales for the year 2001, subtracts returned amounts, and ranks
  categories by profit within each month.
*/
WITH sales_agg AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_category,
        hd.hd_buy_potential,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_quantity_returned,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
        (SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d_sold.d_date >= DATE '2001-01-01'
      AND d_sold.d_date <  DATE '2002-01-01'
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_category,
        hd.hd_buy_potential
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    hd_buy_potential,
    total_quantity_sold,
    total_sales_amount,
    total_net_profit,
    total_quantity_returned,
    total_return_amount,
    net_sales_after_returns,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank_by_category
FROM sales_agg
ORDER BY d_year, d_month_seq, profit_rank_by_category
