WITH per_customer AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        s.s_store_sk,
        s.s_store_name,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ws.ws_net_profit)                     AS total_web_profit,
        SUM(sr.sr_net_loss)                       AS total_store_loss,
        SUM(ws.ws_ext_sales_price)                AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number)        AS web_orders,
        COUNT(DISTINCT sr.sr_ticket_number)       AS store_return_cnt,
        d_ws_sold.d_year                           AS sale_year
    FROM
        customer c
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE
        d_ws_sold.d_year = 2001
        AND d_ws_sold.d_month_seq BETWEEN 1 AND 12
        AND s.s_gmt_offset BETWEEN -5 AND 0
        AND hd.hd_vehicle_count >= 2
        AND c.c_preferred_cust_flag = 'Y'
        AND ws.ws_ext_sales_price > 1000
        AND sr.sr_return_amt > 0
        AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
               OR wr.wr_returning_customer_sk = c.c_customer_sk
        )
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        s.s_store_sk,
        s.s_store_name,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        d_ws_sold.d_year
),
store_summary AS (
    SELECT
        s_store_sk,
        s_store_name,
        AVG(total_web_profit - total_store_loss) AS avg_net_profit,
        SUM(total_web_profit)                    AS sum_web_profit,
        SUM(total_store_loss)                    AS sum_store_loss
    FROM per_customer
    GROUP BY s_store_sk, s_store_name
    HAVING AVG(total_web_profit - total_store_loss) > 5000
)
SELECT
    pc.c_customer_id,
    pc.s_store_name,
    pc.total_web_profit,
    pc.total_store_loss,
    (pc.total_web_profit - pc.total_store_loss) AS net_profit,
    RANK() OVER (PARTITION BY pc.s_store_name ORDER BY (pc.total_web_profit - pc.total_store_loss) DESC) AS profit_rank_within_store,
    AVG(pc.total_sales_amount) OVER (PARTITION BY pc.s_store_name) AS avg_sales_amount_per_customer,
    ss.avg_net_profit,
    pc.sale_year
FROM per_customer pc
JOIN store_summary ss ON pc.s_store_sk = ss.s_store_sk
WHERE (pc.total_web_profit - pc.total_store_loss) > 0
ORDER BY pc.s_store_name, profit_rank_within_store
LIMIT 100
