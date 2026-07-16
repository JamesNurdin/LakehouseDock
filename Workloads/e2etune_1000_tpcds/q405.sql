WITH store_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        d.d_year,
        d.d_month_seq,
        COUNT(sr.sr_ticket_number) AS store_return_cnt,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND c.c_birth_year IN (1966, 1979, 1983)
      AND c.c_salutation = 'Mr.'
    GROUP BY
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        d.d_year,
        d.d_month_seq
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        d.d_year,
        d.d_month_seq,
        COUNT(wr.wr_order_number) AS web_return_cnt,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND c.c_birth_year IN (1966, 1979, 1983)
      AND c.c_salutation = 'Mr.'
    GROUP BY
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        d.d_year,
        d.d_month_seq
),
combined AS (
    SELECT
        COALESCE(s.c_birth_year, w.c_birth_year) AS birth_year,
        COALESCE(s.c_birth_month, w.c_birth_month) AS birth_month,
        COALESCE(s.d_month_seq, w.d_month_seq) AS month_seq,
        SUM(s.store_net_loss) AS total_store_net_loss,
        SUM(w.web_net_loss) AS total_web_net_loss,
        SUM(COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS total_combined_net_loss,
        SUM(s.store_return_cnt) AS total_store_return_cnt,
        SUM(w.web_return_cnt) AS total_web_return_cnt,
        COUNT(DISTINCT COALESCE(s.c_customer_sk, w.c_customer_sk)) AS distinct_customers,
        CASE
            WHEN SUM(COALESCE(w.web_net_loss, 0)) = 0 THEN NULL
            ELSE SUM(COALESCE(s.store_net_loss, 0)) / SUM(COALESCE(w.web_net_loss, 0))
        END AS store_to_web_loss_ratio,
        CASE
            WHEN SUM(s.store_return_cnt) = 0 THEN NULL
            ELSE SUM(s.store_net_loss) / SUM(s.store_return_cnt)
        END AS avg_store_loss_per_return,
        CASE
            WHEN SUM(w.web_return_cnt) = 0 THEN NULL
            ELSE SUM(w.web_net_loss) / SUM(w.web_return_cnt)
        END AS avg_web_loss_per_return
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.c_customer_sk = w.c_customer_sk
        AND s.c_birth_year = w.c_birth_year
        AND s.c_birth_month = w.c_birth_month
        AND s.d_month_seq = w.d_month_seq
    GROUP BY
        COALESCE(s.c_birth_year, w.c_birth_year),
        COALESCE(s.c_birth_month, w.c_birth_month),
        COALESCE(s.d_month_seq, w.d_month_seq)
    HAVING SUM(COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) > 0
)
SELECT
    birth_year,
    birth_month,
    month_seq,
    total_store_net_loss,
    total_web_net_loss,
    total_combined_net_loss,
    total_store_return_cnt,
    total_web_return_cnt,
    avg_store_loss_per_return,
    avg_web_loss_per_return,
    distinct_customers,
    store_to_web_loss_ratio,
    RANK() OVER (ORDER BY total_combined_net_loss DESC) AS loss_rank
FROM combined
ORDER BY total_combined_net_loss DESC
LIMIT 10
