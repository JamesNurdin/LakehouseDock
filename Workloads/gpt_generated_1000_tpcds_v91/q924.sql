WITH all_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_coupon_amt,
        ws.ws_ext_tax,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        d.d_date,
        d.d_year,
        d.d_quarter_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT
    cs_sold_date_sk,
    d_date,
    d_year,
    d_quarter_name,
    cs_order_number,
    cs_quantity,
    cs_sales_price,
    cs_ext_sales_price,
    cs_net_paid_inc_tax,
    cs_net_profit,
    ws_order_number,
    ws_coupon_amt,
    ws_ext_tax,
    sr_return_quantity,
    sr_return_amt,
    sr_net_loss,
    r_reason_desc,
    CASE
        WHEN cs_net_paid_inc_tax > (
            SELECT avg(cs2.cs_net_paid_inc_tax)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = cs_sold_date_sk
        ) THEN 'Above Avg Net Paid'
        ELSE 'Below Avg Net Paid'
    END AS net_paid_category,
    DENSE_RANK() OVER (PARTITION BY d_quarter_name ORDER BY cs_net_paid_inc_tax DESC) AS quarter_sales_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY cs_net_profit DESC) AS yearly_profit_rank
FROM all_data
WHERE
    d_year = 1999
    AND d_date >= DATE '1999-01-01'
    AND d_date < DATE '2000-01-01'
    AND cs_quantity > 2
    AND cs_sales_price BETWEEN 10 AND 100
    AND ws_coupon_amt > 1000
    AND sr_return_quantity = 1
    AND cs_net_profit > 0
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = cs_sold_date_sk
          AND ws2.ws_ext_tax > 50
    )
ORDER BY quarter_sales_rank ASC, cs_ext_sales_price DESC
LIMIT 100
