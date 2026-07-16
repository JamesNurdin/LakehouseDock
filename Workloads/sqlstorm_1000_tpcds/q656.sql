SELECT
    d.d_year,
    i.i_category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit_amount) AS total_profit,
    SUM(f.return_amount) AS total_returns,
    SUM(f.return_loss) AS total_return_loss,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_net_profit AS profit_amount,
           0.0 AS return_amount,
           0.0 AS return_loss,
           cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs

    UNION ALL

    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           -cr.cr_return_amount AS sales_amount,
           -cr.cr_net_loss AS profit_amount,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS return_loss,
           cr.cr_refunded_customer_sk AS customer_sk
    FROM catalog_returns cr

    UNION ALL

    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_ext_sales_price AS sales_amount,
           ss.ss_net_profit AS profit_amount,
           0.0 AS return_amount,
           0.0 AS return_loss,
           ss.ss_customer_sk AS customer_sk
    FROM store_sales ss

    UNION ALL

    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           -sr.sr_return_amt AS sales_amount,
           -sr.sr_net_loss AS profit_amount,
           sr.sr_return_amt AS return_amount,
           sr.sr_net_loss AS return_loss,
           sr.sr_customer_sk AS customer_sk
    FROM store_returns sr

    UNION ALL

    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_ext_sales_price AS sales_amount,
           ws.ws_net_profit AS profit_amount,
           0.0 AS return_amount,
           0.0 AS return_loss,
           ws.ws_bill_customer_sk AS customer_sk
    FROM web_sales ws

    UNION ALL

    SELECT wr.wr_returned_date_sk AS date_sk,
           wr.wr_item_sk AS item_sk,
           -wr.wr_return_amt AS sales_amount,
           -wr.wr_net_loss AS profit_amount,
           wr.wr_return_amt AS return_amount,
           wr.wr_net_loss AS return_loss,
           wr.wr_refunded_customer_sk AS customer_sk
    FROM web_returns wr
) f
JOIN date_dim d ON f.date_sk = d.d_date_sk
JOIN item i ON f.item_sk = i.i_item_sk
JOIN customer c ON f.customer_sk = c.c_customer_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category
