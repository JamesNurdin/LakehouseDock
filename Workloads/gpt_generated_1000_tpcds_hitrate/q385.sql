WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        d.d_year,
        s.s_store_id,
        s.s_state,
        ss.ss_sales_price,
        ws.ws_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        ib.ib_upper_bound,
        wp.wp_type
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
scalar_avg AS (
    SELECT AVG(ss_ext_discount_amt) AS avg_discount
    FROM store_sales
    WHERE ss_sales_price > 0
)
SELECT
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.cd_gender,
    b.d_year,
    b.s_store_id,
    b.s_state,
    b.ss_sales_price,
    b.ws_sales_price,
    CASE WHEN b.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS ss_profit_flag,
    CASE WHEN b.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS ws_profit_flag,
    profit_val,
    v.multiplier,
    profit_val * v.multiplier AS scaled_profit,
    CASE WHEN b.ss_net_profit > b.ws_net_profit THEN 'store' ELSE 'web' END AS higher_profit_source,
    RANK() OVER (PARTITION BY b.s_store_id ORDER BY b.ss_ext_sales_price DESC) AS store_sales_rank,
    a.avg_discount
FROM (
    SELECT
        *,
        ARRAY[b.ss_net_profit, b.ws_net_profit] AS profit_array
    FROM base b
) b
CROSS JOIN UNNEST(b.profit_array) AS t(profit_val)
CROSS JOIN (VALUES 1, 2) AS v(multiplier)
CROSS JOIN scalar_avg a
WHERE
    b.d_year = 2001
    AND b.s_state = 'CA'
    AND b.ib_upper_bound < 50000
    AND b.wp_type = 'home'
    AND b.c_customer_sk NOT IN (
        SELECT sr_customer_sk FROM store_returns WHERE sr_return_quantity > 5
    )
ORDER BY b.s_store_id, store_sales_rank, scaled_profit DESC
LIMIT 100
