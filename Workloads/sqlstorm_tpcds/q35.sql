WITH
catalog_channel AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0) - COALESCE(p.p_cost, 0)) AS profit,
        SUM(cs.cs_ext_sales_price) AS sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id, d.d_year, d.d_month_seq
),
store_channel AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0) - COALESCE(p.p_cost, 0)) AS profit,
        SUM(ss.ss_ext_sales_price) AS sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id, d.d_year, d.d_month_seq
),
web_channel AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0) - COALESCE(p.p_cost, 0)) AS profit,
        SUM(ws.ws_ext_sales_price) AS sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN promotion p ON p.p_promo_sk = ws.ws_promo_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id, d.d_year, d.d_month_seq
),
combined AS (
    SELECT * FROM catalog_channel
    UNION ALL
    SELECT * FROM store_channel
    UNION ALL
    SELECT * FROM web_channel
),
agg AS (
    SELECT 
        c_customer_id,
        d_year,
        d_month_seq,
        SUM(profit) AS total_profit,
        SUM(sales) AS total_sales,
        SUM(orders) AS total_orders
    FROM combined
    GROUP BY c_customer_id, d_year, d_month_seq
),
customer_seg AS (
    SELECT 
        c.c_customer_id AS c_customer_id,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        hd.hd_buy_potential AS buy_potential,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper
    FROM customer c
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
)
SELECT 
    a.c_customer_id,
    cs.gender,
    cs.marital_status,
    cs.buy_potential,
    cs.income_lower,
    cs.income_upper,
    a.d_year,
    a.d_month_seq,
    a.total_profit,
    a.total_sales,
    a.total_orders,
    rank() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
JOIN customer_seg cs ON cs.c_customer_id = a.c_customer_id
WHERE a.total_profit > 0
ORDER BY a.d_year, a.d_month_seq, profit_rank
LIMIT 200
