WITH base AS (
    SELECT
        d_cs_sold.d_year,
        i.i_category,
        cd_cs_bill.cd_gender,
        cd_cs_bill.cd_credit_rating,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(cr.cr_return_amount) AS returns_amount,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(CASE WHEN cd_cs_bill.cd_credit_rating = 'Good' THEN cs.cs_net_profit + ws.ws_net_profit ELSE 0 END) AS good_credit_total_profit
    FROM catalog_sales cs
    JOIN date_dim d_cs_sold
      ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN time_dim t_cs_sold
      ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    JOIN date_dim d_cs_ship
      ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN customer_demographics cd_cs_bill
      ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
    JOIN customer_demographics cd_cs_ship
      ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
         AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN date_dim d_cr_returned
      ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
    LEFT JOIN time_dim t_cr_returned
      ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
    LEFT JOIN customer_demographics cd_cr_refunded
      ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    LEFT JOIN customer_demographics cd_cr_returning
      ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws_sold
      ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold
      ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN date_dim d_ws_ship
      ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer_demographics cd_ws_bill
      ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN customer_demographics cd_ws_ship
      ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    WHERE d_cs_sold.d_year = 2001
      AND i.i_category = 'Electronics'
      AND cd_cs_bill.cd_credit_rating = 'Good'
      AND t_cs_sold.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_quantity > 0
      AND d_ws_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d_cs_sold.d_year, i.i_category, cd_cs_bill.cd_gender, cd_cs_bill.cd_credit_rating
)
SELECT
    b.d_year,
    b.i_category,
    b.cd_gender,
    b.cd_credit_rating,
    b.orders,
    b.catalog_sales,
    b.web_sales,
    b.returns_amount,
    b.catalog_profit,
    b.web_profit,
    b.good_credit_total_profit,
    SUM(b.catalog_sales + b.web_sales) OVER (PARTITION BY b.i_category ORDER BY b.d_year) AS cumulative_sales_by_category
FROM base b
ORDER BY b.d_year, b.i_category, b.cd_gender
