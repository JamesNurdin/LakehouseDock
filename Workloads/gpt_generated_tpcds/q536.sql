WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
),
returns_data AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_returned_date_sk
    FROM web_returns wr
),
sales_joined AS (
    SELECT
        sd.d_year,
        sd.d_moy,
        s.ws_net_profit,
        s.ws_ext_sales_price,
        s.ws_ext_discount_amt,
        s.ws_bill_customer_sk,
        s.ws_bill_cdemo_sk,
        s.ws_web_site_sk,
        s.ws_order_number
    FROM sales_data s
    JOIN date_dim sd ON s.ws_sold_date_sk = sd.d_date_sk
),
returns_joined AS (
    SELECT
        rd.d_year AS return_year,
        rd.d_moy AS return_month,
        r.wr_return_amt,
        r.wr_net_loss,
        r.wr_order_number
    FROM returns_data r
    JOIN date_dim rd ON r.wr_returned_date_sk = rd.d_date_sk
)
SELECT
    site.web_name,
    s.d_year,
    s.d_moy,
    cd.cd_gender,
    SUM(s.ws_net_profit) AS total_net_profit,
    SUM(s.ws_ext_sales_price) AS total_sales,
    AVG(s.ws_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT s.ws_bill_customer_sk) AS distinct_customers,
    COALESCE(SUM(r.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(r.wr_net_loss), 0) AS total_return_loss
FROM sales_joined s
JOIN web_site site ON s.ws_web_site_sk = site.web_site_sk
JOIN customer_demographics cd ON s.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_joined r ON s.ws_order_number = r.wr_order_number
WHERE s.d_year BETWEEN 1999 AND 2001
GROUP BY site.web_name, s.d_year, s.d_moy, cd.cd_gender
ORDER BY site.web_name, s.d_year, s.d_moy, cd.cd_gender
