WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 100
      AND cs.cs_net_profit > 0
      AND cs.cs_sold_date_sk BETWEEN 2451011 AND 2451513
      AND cs.cs_bill_hdemo_sk IS NOT NULL
),
ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_quantity >= 2
      AND ws.ws_ext_sales_price > 150
      AND ws.ws_net_profit > 0
      AND ws.ws_sold_date_sk BETWEEN 2451011 AND 2451513
      AND ws.ws_bill_hdemo_sk IS NOT NULL
),
wr AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        wr.wr_reason_sk,
        wr.wr_returned_date_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 50
      AND wr.wr_refunded_cash > 20
      AND wr.wr_reason_sk IN (11, 22, 40)
      AND wr.wr_returned_date_sk BETWEEN 2451011 AND 2451513
),
dd AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq
    FROM date_dim d
    WHERE d.d_year IN (2000, 2001)
),
hd AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM household_demographics hd
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count <= 4
)
SELECT
    dd.d_year,
    hd.hd_income_band_sk,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(cs.cs_net_profit) AS catalog_profit_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(ws.ws_net_profit) AS web_profit_total,
    SUM(wr.wr_return_amt) AS total_return_amount,
    CASE
        WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_return_amt)) > 0 THEN 'POSITIVE'
        ELSE 'NEGATIVE'
    END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY dd.d_year ORDER BY (SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price)) DESC) AS sales_rank
FROM cs
JOIN dd ON cs.cs_sold_date_sk = dd.d_date_sk
JOIN hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN ws ON ws.ws_sold_date_sk = dd.d_date_sk
     AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN wr ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
WHERE dd.d_month_seq BETWEEN 1200 AND 1210
GROUP BY dd.d_year, hd.hd_income_band_sk
HAVING SUM(cs.cs_ext_sales_price) > 5000
   AND SUM(ws.ws_ext_sales_price) > 4000
   AND COUNT(DISTINCT cs.cs_order_number) >= 5
ORDER BY catalog_sales_total DESC
LIMIT 100
