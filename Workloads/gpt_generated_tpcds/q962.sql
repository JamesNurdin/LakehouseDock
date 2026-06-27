WITH store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        AVG(ss.ss_ext_discount_amt) AS store_avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_unique_customers
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        AVG(ws.ws_ext_discount_amt) AS web_avg_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_unique_customers
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.store_net_paid,
    s.store_net_profit,
    s.store_avg_discount,
    s.store_unique_customers,
    w.web_net_paid,
    w.web_net_profit,
    w.web_avg_discount,
    w.web_unique_customers,
    CASE
        WHEN w.web_net_profit <> 0 THEN s.store_net_profit / w.web_net_profit
        ELSE NULL
    END AS store_to_web_profit_ratio
FROM store_agg s
JOIN web_agg w
    ON s.d_year = w.d_year
    AND s.d_month_seq = w.d_month_seq
    AND s.i_category = w.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
