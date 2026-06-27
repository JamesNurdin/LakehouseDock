SELECT
    sd.d_year AS sales_year,
    sd.d_moy AS sales_month,
    cd.cd_gender,
    i.i_category,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    CASE
        WHEN SUM(ws.ws_quantity) = 0 THEN 0
        ELSE SUM(COALESCE(wr.wr_return_quantity, 0)) * 1.0 / SUM(ws.ws_quantity)
    END AS return_rate,
    SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_profit_after_returns
FROM
    web_sales ws
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
WHERE
    sd.d_date >= DATE '1998-01-01'
    AND sd.d_date < DATE '1999-01-01'
GROUP BY
    sd.d_year,
    sd.d_moy,
    cd.cd_gender,
    i.i_category
ORDER BY
    sd.d_year,
    sd.d_moy,
    total_net_profit DESC
