WITH cs_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_ship_mode_id,
        w.w_state,
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, sm.sm_ship_mode_id, w.w_state, cs.cs_bill_customer_sk
),
ws_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_sk AS customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, c.c_customer_sk
),
wr_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, wr.wr_returning_customer_sk
)
SELECT *
FROM (
    SELECT
        ca.d_year,
        ca.d_month_seq,
        ca.sm_ship_mode_id,
        ca.w_state,
        ca.customer_sk,
        ca.total_sales AS catalog_sales,
        COALESCE(ws.total_sales, 0) AS store_sales,
        COALESCE(wr.total_return_amount, 0) AS returns_amount,
        (ca.total_profit + COALESCE(ws.total_profit, 0) - COALESCE(wr.total_net_loss, 0)) AS net_profit,
        (ca.total_profit + COALESCE(ws.total_profit, 0) - COALESCE(wr.total_net_loss, 0)) /
            NULLIF((ca.total_sales + COALESCE(ws.total_sales, 0) - COALESCE(wr.total_return_amount, 0)), 0) AS profit_margin,
        RANK() OVER (PARTITION BY ca.sm_ship_mode_id, ca.w_state ORDER BY (ca.total_profit + COALESCE(ws.total_profit, 0) - COALESCE(wr.total_net_loss, 0)) DESC) AS profit_rank
    FROM cs_agg ca
    LEFT JOIN ws_agg ws
        ON ca.d_year = ws.d_year
        AND ca.d_month_seq = ws.d_month_seq
        AND ca.customer_sk = ws.customer_sk
    LEFT JOIN wr_agg wr
        ON ca.d_year = wr.d_year
        AND ca.d_month_seq = wr.d_month_seq
        AND ca.customer_sk = wr.customer_sk
    WHERE ca.total_sales > 10000
) t
WHERE t.profit_rank <= 10
ORDER BY t.net_profit DESC
LIMIT 100
