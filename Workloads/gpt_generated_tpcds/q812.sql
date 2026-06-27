WITH store_sales_agg AS (
    SELECT
        ds.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ds.d_year BETWEEN 1999 AND 2002
    GROUP BY ds.d_year
),
store_returns_agg AS (
    SELECT
        dr.d_year,
        SUM(sr.sr_return_amt) AS return_amt,
        SUM(sr.sr_net_loss) AS return_net_loss
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND dr.d_year BETWEEN 1999 AND 2002
    GROUP BY dr.d_year
),
web_sales_agg AS (
    SELECT
        dw.d_year,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND dw.d_year BETWEEN 1999 AND 2002
    GROUP BY dw.d_year
)
SELECT
    ss.d_year,
    ss.store_net_paid,
    ss.store_net_profit,
    COALESCE(sr.return_amt, 0) AS return_amt,
    COALESCE(sr.return_net_loss, 0) AS return_net_loss,
    ws.web_net_paid,
    ws.web_net_profit,
    (COALESCE(sr.return_amt, 0) / NULLIF(ss.store_net_paid, 0)) AS return_rate
FROM store_sales_agg ss
LEFT JOIN store_returns_agg sr ON ss.d_year = sr.d_year
LEFT JOIN web_sales_agg ws ON ss.d_year = ws.d_year
ORDER BY ss.d_year
