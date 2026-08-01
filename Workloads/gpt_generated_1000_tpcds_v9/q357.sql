WITH cs AS (
    SELECT
        cs.cs_order_number AS cs_order_number,
        d.d_year AS d_year,
        c.c_customer_id AS c_customer_id,
        hd.hd_income_band_sk AS hd_income_band_sk,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_profit AS cs_net_profit,
        d.d_date_sk AS d_date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cs.cs_ext_sales_price > 1000
      AND NOT EXISTS (
          SELECT 1
          FROM inventory i
          JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
          WHERE d2.d_date_sk = d.d_date_sk
      )
),
ws AS (
    SELECT
        ws.ws_order_number AS ws_order_number,
        d.d_year AS d_year,
        c.c_customer_id AS c_customer_id,
        hd.hd_income_band_sk AS hd_income_band_sk,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        d.d_date_sk AS d_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_sales_price > 1000
      AND NOT EXISTS (
          SELECT 1
          FROM inventory i
          JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
          WHERE d2.d_date_sk = d.d_date_sk
      )
),
avg_profit AS (
    SELECT
        d_year,
        AVG(net_profit) AS avg_year_profit
    FROM (
        SELECT d_year, cs_net_profit AS net_profit FROM cs
        UNION ALL
        SELECT d_year, ws_net_profit AS net_profit FROM ws
    ) combined_profit
    GROUP BY d_year
)
SELECT
    combined.order_number,
    combined.d_year,
    combined.c_customer_id,
    combined.hd_income_band_sk,
    combined.sales_price,
    combined.net_profit
FROM (
    SELECT
        cs_order_number AS order_number,
        d_year,
        c_customer_id,
        hd_income_band_sk,
        cs_ext_sales_price AS sales_price,
        cs_net_profit AS net_profit
    FROM cs
    UNION ALL
    SELECT
        ws_order_number AS order_number,
        d_year,
        c_customer_id,
        hd_income_band_sk,
        ws_ext_sales_price AS sales_price,
        ws_net_profit AS net_profit
    FROM ws
) combined
WHERE combined.net_profit > (
    SELECT avg_year_profit
    FROM avg_profit
    WHERE avg_profit.d_year = combined.d_year
)
ORDER BY combined.d_year DESC, combined.net_profit DESC
LIMIT 100
