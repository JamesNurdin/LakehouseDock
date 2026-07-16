WITH web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
),
store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(w.i_item_sk, s.i_item_sk) AS item_sk,
    COALESCE(w.i_category, s.i_category) AS category,
    COALESCE(w.d_year, s.d_year) AS sales_year,
    COALESCE(w.d_month_seq, s.d_month_seq) AS month_seq,
    w.web_sales_amount,
    s.store_sales_amount,
    w.web_net_profit,
    s.store_net_profit,
    COALESCE(w.web_sales_amount, 0) + COALESCE(s.store_sales_amount, 0) AS total_sales_amount,
    COALESCE(w.web_net_profit, 0) + COALESCE(s.store_net_profit, 0) AS total_net_profit,
    CASE
        WHEN COALESCE(w.web_sales_amount, 0) + COALESCE(s.store_sales_amount, 0) = 0 THEN 0
        ELSE (COALESCE(w.web_net_profit, 0) + COALESCE(s.store_net_profit, 0)) /
             (COALESCE(w.web_sales_amount, 0) + COALESCE(s.store_sales_amount, 0))
    END AS overall_profit_margin
FROM web_agg w
FULL OUTER JOIN store_agg s
    ON w.i_item_sk = s.i_item_sk
    AND w.d_year = s.d_year
    AND w.d_month_seq = s.d_month_seq
ORDER BY sales_year, month_seq, total_sales_amount DESC
LIMIT 20
