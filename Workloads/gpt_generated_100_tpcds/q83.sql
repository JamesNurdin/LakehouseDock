WITH sales_enriched AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_category,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        date_format(ds.d_date, '%Y-%m') AS sold_month,
        cd.cd_gender,
        cd.cd_marital_status
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ds.d_date >= DATE '2022-01-01' AND ds.d_date < DATE '2023-01-01'
),
returns_enriched AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_net_loss,
        date_format(dr.d_date, '%Y-%m') AS returned_month,
        r.r_reason_desc
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE dr.d_date >= DATE '2022-01-01' AND dr.d_date < DATE '2023-01-01'
)
SELECT
    se.sold_month,
    se.i_category,
    se.cd_gender,
    se.cd_marital_status,
    COUNT(DISTINCT se.ws_order_number) AS orders,
    SUM(se.ws_quantity) AS total_quantity_sold,
    SUM(se.ws_ext_sales_price) AS total_sales_amount,
    SUM(se.ws_ext_discount_amt) AS total_discount_amount,
    AVG(CASE WHEN se.ws_ext_sales_price > 0 THEN se.ws_ext_discount_amt / se.ws_ext_sales_price END) AS avg_discount_rate,
    SUM(se.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(r.wr_net_loss), 0) AS total_return_loss,
    SUM(se.ws_net_profit) - COALESCE(SUM(r.wr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons
FROM sales_enriched se
LEFT JOIN returns_enriched r
    ON se.ws_order_number = r.wr_order_number
    AND se.ws_item_sk = r.wr_item_sk
    AND se.sold_month = r.returned_month
GROUP BY
    se.sold_month,
    se.i_category,
    se.cd_gender,
    se.cd_marital_status
ORDER BY net_profit_after_returns DESC
LIMIT 100
