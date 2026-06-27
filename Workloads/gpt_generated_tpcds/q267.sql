WITH store_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(s.p_promo_id, c.p_promo_id, w.p_promo_id) AS promo_id,
    COALESCE(s.d_year, c.d_year, w.d_year) AS year,
    COALESCE(s.d_month_seq, c.d_month_seq, w.d_month_seq) AS month_seq,
    s.store_net_paid,
    s.store_net_profit,
    c.catalog_net_paid,
    c.catalog_net_profit,
    w.web_net_paid,
    w.web_net_profit,
    COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0) AS total_net_paid,
    COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit
FROM store_sales_agg s
FULL OUTER JOIN catalog_sales_agg c
    ON s.p_promo_id = c.p_promo_id
   AND s.d_year = c.d_year
   AND s.d_month_seq = c.d_month_seq
FULL OUTER JOIN web_sales_agg w
    ON COALESCE(s.p_promo_id, c.p_promo_id) = w.p_promo_id
   AND COALESCE(s.d_year, c.d_year) = w.d_year
   AND COALESCE(s.d_month_seq, c.d_month_seq) = w.d_month_seq
ORDER BY promo_id, year, month_seq
