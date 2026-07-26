WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS sales_txn_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_txn_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
),
household_day_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        COUNT(DISTINCT hd.hd_buy_potential) AS distinct_buy_potential_cnt
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
customer_day_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        COUNT(DISTINCT cd.cd_credit_rating) AS distinct_credit_rating_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
combined AS (
    SELECT
        COALESCE(s.ss_store_sk, r.sr_store_sk) AS store_sk,
        COALESCE(s.ss_sold_date_sk, r.sr_returned_date_sk) AS date_sk,
        COALESCE(s.total_sales_profit, 0) AS sales_profit,
        COALESCE(r.total_return_loss, 0) AS return_loss,
        (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_margin,
        COALESCE(s.sales_txn_cnt, 0) AS sales_txn_cnt,
        COALESCE(r.return_txn_cnt, 0) AS return_txn_cnt,
        COALESCE(hd.distinct_buy_potential_cnt, 0) AS distinct_buy_potential_cnt,
        COALESCE(cd.distinct_credit_rating_cnt, 0) AS distinct_credit_rating_cnt
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.ss_store_sk = r.sr_store_sk
        AND s.ss_sold_date_sk = r.sr_returned_date_sk
    LEFT JOIN household_day_agg hd
        ON COALESCE(s.ss_store_sk, r.sr_store_sk) = hd.ss_store_sk
        AND COALESCE(s.ss_sold_date_sk, r.sr_returned_date_sk) = hd.ss_sold_date_sk
    LEFT JOIN customer_day_agg cd
        ON COALESCE(s.ss_store_sk, r.sr_store_sk) = cd.ss_store_sk
        AND COALESCE(s.ss_sold_date_sk, r.sr_returned_date_sk) = cd.ss_sold_date_sk
)
SELECT
    store_sk,
    date_sk,
    sales_profit,
    return_loss,
    net_margin,
    CASE
        WHEN net_margin >= 100000 THEN 'HIGH'
        WHEN net_margin >= 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_margin_category,
    RANK() OVER (PARTITION BY date_sk ORDER BY net_margin DESC) AS margin_rank,
    distinct_buy_potential_cnt,
    distinct_credit_rating_cnt
FROM combined
WHERE store_sk IS NOT NULL
ORDER BY date_sk DESC, margin_rank
LIMIT 100
