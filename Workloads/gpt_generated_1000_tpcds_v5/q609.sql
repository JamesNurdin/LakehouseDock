WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_buy_potential IN ('501-1000', '>10000')
        AND hd.hd_dep_count BETWEEN 1 AND 6
        AND hd.hd_income_band_sk >= 10
        AND ws.ws_web_page_sk IN (369, 1105)
        AND ws.ws_list_price > 50
        AND c.c_current_hdemo_sk IS NOT NULL
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY
        c.c_customer_id,
        hd.hd_buy_potential,
        hd.hd_dep_count
)
SELECT
    c_customer_id,
    hd_buy_potential,
    hd_dep_count,
    SUM(total_sales) AS sum_sales,
    AVG(total_profit) AS avg_profit,
    SUM(order_cnt) AS total_orders
FROM sales_agg
GROUP BY GROUPING SETS (
    (c_customer_id, hd_buy_potential, hd_dep_count),
    (c_customer_id, hd_buy_potential),
    (c_customer_id),
    ()
)
ORDER BY sum_sales DESC
LIMIT 100
