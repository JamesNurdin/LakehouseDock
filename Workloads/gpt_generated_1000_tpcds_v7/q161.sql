WITH sales_agg AS (
    SELECT
        hd.hd_buy_potential,
        td.t_shift,
        concat(hd.hd_buy_potential, '_', td.t_shift) AS buy_shift,
        regexp_extract(hd.hd_buy_potential, '(\\d+)', 1) AS extracted_number,
        sum(ws.ws_net_profit) AS total_profit,
        count(DISTINCT ws.ws_order_number) AS num_orders
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE regexp_like(hd.hd_buy_potential, '^[A-Z]{2,}$')
      AND td.t_time_id LIKE 'T_%'
    GROUP BY
        hd.hd_buy_potential,
        td.t_shift,
        concat(hd.hd_buy_potential, '_', td.t_shift),
        regexp_extract(hd.hd_buy_potential, '(\\d+)', 1)
)
SELECT
    buy_shift,
    extracted_number,
    total_profit,
    num_orders,
    rank() OVER (ORDER BY total_profit DESC) AS profit_rank,
    substr(buy_shift, 1, 5) AS buy_prefix
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 20
