WITH sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_ship_date_sk AS ship_date_sk,
        ws.ws_bill_cdemo_sk AS bill_demo_sk,
        ws.ws_ship_cdemo_sk AS ship_demo_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk
),
returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_refunded_cdemo_sk AS refunded_demo_sk,
        cr.cr_returning_cdemo_sk AS returning_demo_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    GROUP BY
        cr.cr_returned_date_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk
)

SELECT
    s.s_store_id,
    d_sold.d_current_month AS sales_month,
    d_ship.d_current_month AS ship_month,
    s.s_city,
    s.s_state,
    COALESCE(sa.total_sales, 0) AS month_sales,
    COALESCE(sa.total_profit, 0) AS month_profit,
    COALESCE(ra.total_return_loss, 0) AS month_return_loss,
    COALESCE(sa.sales_cnt, 0) AS sales_transactions,
    COALESCE(ra.returns_cnt, 0) AS return_transactions,
    cd_bill.cd_credit_rating AS bill_customer_credit_rating,
    cd_ship.cd_credit_rating AS ship_customer_credit_rating,
    cd_refunded.cd_credit_rating AS refunded_customer_credit_rating,
    cd_returning.cd_credit_rating AS returning_customer_credit_rating,
    ROW_NUMBER() OVER (
        PARTITION BY d_sold.d_current_month
        ORDER BY COALESCE(sa.total_sales, 0) DESC
    ) AS sales_rank
FROM date_dim d_sold
LEFT JOIN sales_agg sa ON sa.sold_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_ship ON sa.ship_date_sk = d_ship.d_date_sk
LEFT JOIN returns_agg ra ON ra.returned_date_sk = d_sold.d_date_sk
LEFT JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN customer_demographics cd_bill ON sa.bill_demo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ship ON sa.ship_demo_sk = cd_ship.cd_demo_sk
LEFT JOIN customer_demographics cd_refunded ON ra.refunded_demo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning ON ra.returning_demo_sk = cd_returning.cd_demo_sk
WHERE d_sold.d_year = 2001
ORDER BY month_sales DESC
LIMIT 100
