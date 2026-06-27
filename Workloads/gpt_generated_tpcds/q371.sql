WITH sales_data AS (
    SELECT
        i.i_category,
        date_format(d.d_date, '%Y-%m') AS sale_month,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_order_number,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wr.wr_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND d.d_year = 2001
)
SELECT
    i_category,
    sale_month,
    sum(ws_ext_sales_price) AS total_sales_amount,
    sum(ws_ext_discount_amt) AS total_discount_amount,
    avg(ws_ext_discount_amt) AS avg_discount_per_sale,
    sum(ws_net_profit) AS total_net_profit,
    sum(coalesce(wr_return_amt_inc_tax, 0)) AS total_return_amount,
    sum(coalesce(wr_net_loss, 0)) AS total_return_loss,
    sum(ws_net_profit) - sum(coalesce(wr_net_loss, 0)) AS net_profit_after_returns,
    sum(coalesce(wr_return_amt_inc_tax, 0)) / nullif(sum(ws_ext_sales_price), 0) AS return_rate,
    count(distinct ws_order_number) AS orders_count,
    count(distinct wr_order_number) AS returns_count
FROM sales_data
GROUP BY i_category, sale_month
ORDER BY i_category, sale_month
