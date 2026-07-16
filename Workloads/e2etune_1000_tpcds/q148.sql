WITH sales_agg AS (
    SELECT
        s.s_market_desc,
        ib.ib_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM
        store s
    JOIN
        web_sales ws
        ON s.s_store_sk = ws.ws_warehouse_sk
    JOIN
        income_band ib
        ON ws.ws_net_paid BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE
        s.s_closed_date_sk IS NOT NULL
        AND s.s_state = 'CA'
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY
        s.s_market_desc,
        ib.ib_income_band_sk
    HAVING
        SUM(ws.ws_net_paid) > 10000
)
SELECT
    s_market_desc,
    ib_income_band_sk,
    num_orders,
    total_net_paid,
    avg_profit,
    total_discount,
    RANK() OVER (ORDER BY total_net_paid DESC) AS market_income_rank
FROM
    sales_agg
ORDER BY
    total_net_paid DESC
LIMIT 50
