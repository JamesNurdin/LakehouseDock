WITH sales_returns_item AS (
    SELECT
        s.ss_store_sk AS store_sk,
        s.ss_sold_date_sk AS sold_date_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        SUM(r.sr_return_amt_inc_tax) AS total_returns,
        SUM(r.sr_net_loss) AS net_loss
    FROM store_sales s
    JOIN store_returns r
        ON s.ss_item_sk = r.sr_item_sk
    WHERE s.ss_ext_sales_price > 2000
      AND r.sr_refunded_cash > 100
    GROUP BY s.ss_store_sk, s.ss_sold_date_sk
),
sales_returns_ticket AS (
    SELECT
        s.ss_store_sk AS store_sk,
        s.ss_sold_date_sk AS sold_date_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        SUM(r.sr_return_amt_inc_tax) AS total_returns,
        SUM(r.sr_net_loss) AS net_loss
    FROM store_sales s
    JOIN store_returns r
        ON s.ss_ticket_number = r.sr_ticket_number
    WHERE s.ss_ext_sales_price <= 2000
      AND r.sr_refunded_cash <= 100
    GROUP BY s.ss_store_sk, s.ss_sold_date_sk
)
SELECT store_sk, sold_date_sk, total_sales, total_returns, net_loss
FROM sales_returns_item
UNION ALL
SELECT store_sk, sold_date_sk, total_sales, total_returns, net_loss
FROM sales_returns_ticket
ORDER BY total_sales DESC
LIMIT 100
