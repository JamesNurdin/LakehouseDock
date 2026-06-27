WITH returns_detail AS (
    -- Catalog returns with reason and customer gender
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2020
    UNION ALL
    -- Store returns with reason and customer gender
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2020
),
returns_agg AS (
    SELECT
        year,
        month_seq,
        reason_desc,
        gender,
        SUM(net_loss) AS total_net_loss
    FROM returns_detail
    GROUP BY year, month_seq, reason_desc, gender
),
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_net_paid) AS total_store_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_net_paid) AS total_web_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_month_seq
),
total_sales AS (
    SELECT
        COALESCE(s.year, w.year) AS year,
        COALESCE(s.month_seq, w.month_seq) AS month_seq,
        COALESCE(s.total_store_net_paid, 0) + COALESCE(w.total_web_net_paid, 0) AS total_net_paid
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.year = w.year AND s.month_seq = w.month_seq
)
SELECT
    r.year,
    r.month_seq,
    r.reason_desc,
    r.gender,
    r.total_net_loss,
    t.total_net_paid,
    (r.total_net_loss / NULLIF(t.total_net_paid, 0)) * 100 AS net_loss_pct_of_sales
FROM returns_agg r
JOIN total_sales t
    ON r.year = t.year AND r.month_seq = t.month_seq
ORDER BY r.year, r.month_seq, r.total_net_loss DESC
