WITH catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_bill_hdemo_sk AS demo_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(*) AS catalog_orders
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_wholesale_cost > 10
      AND cs.cs_ext_discount_amt BETWEEN 0 AND 100
    GROUP BY cs.cs_bill_customer_sk, cs.cs_bill_hdemo_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_bill_hdemo_sk AS demo_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_quantity > 0
      AND ws.ws_list_price > 50
      AND ws.ws_ext_discount_amt < 20
    GROUP BY ws.ws_bill_customer_sk, ws.ws_bill_hdemo_sk
),
returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        wr.wr_refunded_hdemo_sk AS demo_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND wr.wr_fee < 50
    GROUP BY wr.wr_refunded_customer_sk, wr.wr_refunded_hdemo_sk
)
SELECT
    c.c_customer_id AS customer_id,
    hd.hd_income_band_sk,
    (ca.total_catalog_sales + ws.total_web_sales - r.total_return_amount) AS net_sales,
    ca.catalog_orders,
    ws.web_orders,
    r.return_cnt
FROM catalog_agg ca
JOIN web_sales_agg ws
    ON ca.cust_sk = ws.cust_sk AND ca.demo_sk = ws.demo_sk
JOIN returns_agg r
    ON ca.cust_sk = r.cust_sk AND ca.demo_sk = r.demo_sk
JOIN customer c
    ON ca.cust_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ca.demo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 0
  AND hd.hd_income_band_sk IN (3, 5, 14, 15)
  AND c.c_preferred_cust_flag = 'Y'
  AND ca.total_catalog_sales > 1000
  AND ws.total_web_sales > 500
  AND r.total_return_amount < 2000
  AND EXISTS (
        SELECT 1
        FROM web_returns wr_sub
        WHERE wr_sub.wr_refunded_customer_sk = c.c_customer_sk
          AND wr_sub.wr_return_amt > 150
    )
  AND (ca.total_catalog_sales + ws.total_web_sales - r.total_return_amount) > (
        SELECT AVG(ca2.total_catalog_sales + ws2.total_web_sales - r2.total_return_amount)
        FROM catalog_agg ca2
        JOIN web_sales_agg ws2 ON ca2.cust_sk = ws2.cust_sk AND ca2.demo_sk = ws2.demo_sk
        JOIN returns_agg r2 ON ca2.cust_sk = r2.cust_sk AND ca2.demo_sk = r2.demo_sk
    )
ORDER BY net_sales DESC
LIMIT 100
