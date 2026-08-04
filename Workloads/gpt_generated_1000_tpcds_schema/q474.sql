WITH cs_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_bill_customer_sk IN (
        SELECT cs_bill_customer_sk
        FROM catalog_sales
        WHERE cs_ext_ship_cost > 1000
    )
),
order_keep AS (
    SELECT ws_order_number AS ord_num
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
)
SELECT
    cs.cs_order_number,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    wp.wp_type,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_order_number = cs.cs_order_number
    ) AS order_return_total,
    (
        SELECT SUM(wr3.wr_return_amt)
        FROM web_returns wr3
        WHERE wr3.wr_order_number = ws.ws_order_number
    ) AS ws_order_return_total
FROM cs_sample cs
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ws_ship
  ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
FULL OUTER JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN customer_demographics cd_refunded
  ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning
  ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN web_page wp_wr
  ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE cs.cs_item_sk IN (
        SELECT ws_inner.ws_item_sk
        FROM web_sales ws_inner
        WHERE ws_inner.ws_quantity > 5
    )
  AND ws.ws_order_number IN (SELECT ord_num FROM order_keep)
GROUP BY
    cs.cs_order_number,
    cd_bill.cd_gender,
    cd_ship.cd_gender,
    wp.wp_type,
    ws.ws_order_number
ORDER BY total_catalog_sales DESC
LIMIT 100
