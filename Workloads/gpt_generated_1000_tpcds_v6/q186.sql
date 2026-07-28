WITH avg_sales AS (
    SELECT
        hd_buy_potential,
        AVG(total_sales) AS avg_total_sales
    FROM (
        SELECT
            hd.hd_buy_potential,
            ws.ws_order_number,
            SUM(ws.ws_ext_sales_price) AS total_sales
        FROM web_sales ws
        JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        GROUP BY hd.hd_buy_potential, ws.ws_order_number
    ) t
    GROUP BY hd_buy_potential
),
sales_rank AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        hd.hd_buy_potential,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_in_potential
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_wholesale_cost > 30
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk, hd.hd_buy_potential
)

SELECT
    sr.ws_order_number AS order_number,
    sr.ws_sold_date_sk AS sold_date_sk,
    sr.hd_buy_potential AS buy_potential,
    sr.total_sales,
    sr.total_profit,
    sr.rank_in_potential
FROM sales_rank sr
JOIN avg_sales a
    ON sr.hd_buy_potential = a.hd_buy_potential
WHERE sr.hd_buy_potential = '501-1000'
  AND sr.total_sales > a.avg_total_sales

UNION ALL

SELECT
    ws.ws_order_number AS order_number,
    ws.ws_sold_date_sk AS sold_date_sk,
    hd.hd_buy_potential AS buy_potential,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_in_potential
FROM web_sales ws
JOIN household_demographics hd
    ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential = '>10000'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_amt > 100
    )
GROUP BY ws.ws_order_number, ws.ws_sold_date_sk, hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
