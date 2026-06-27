WITH store_sales_agg AS (
    SELECT
        ss.ss_promo_sk,
        d.d_year,
        d.d_month_seq,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_net_profit) AS total_net_profit,
        count(*) AS store_txn_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_promo_sk, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        ws.ws_promo_sk,
        d.d_year,
        d.d_month_seq,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_net_profit) AS total_net_profit,
        count(*) AS web_txn_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_promo_sk, d.d_year, d.d_month_seq
),
combined_sales AS (
    SELECT
        COALESCE(s.ss_promo_sk, w.ws_promo_sk) AS promo_sk,
        COALESCE(s.d_year, w.d_year) AS sale_year,
        COALESCE(s.d_month_seq, w.d_month_seq) AS sale_month_seq,
        COALESCE(s.total_net_paid, 0) + COALESCE(w.total_net_paid, 0) AS total_net_paid,
        COALESCE(s.total_net_profit, 0) + COALESCE(w.total_net_profit, 0) AS total_net_profit,
        COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0) AS total_txn_count
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.ss_promo_sk = w.ws_promo_sk
        AND s.d_year = w.d_year
        AND s.d_month_seq = w.d_month_seq
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    c.sale_year,
    c.sale_month_seq,
    c.total_net_paid,
    c.total_net_profit,
    c.total_txn_count,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date
FROM combined_sales c
JOIN promotion p ON c.promo_sk = p.p_promo_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE c.sale_year = 2001
ORDER BY c.total_net_paid DESC
LIMIT 20
