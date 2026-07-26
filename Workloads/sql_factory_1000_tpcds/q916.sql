WITH sales_item AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT hd.hd_buy_potential) AS distinct_buy_potential_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ss.ss_item_sk, ss.ss_store_sk
),
returns_item AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS return_amount,
        SUM(sr.sr_refunded_cash) AS refunded_cash,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_store_sk
),
item_combined AS (
    SELECT
        COALESCE(s.ss_item_sk, r.sr_item_sk) AS item_sk,
        COALESCE(s.ss_store_sk, r.sr_store_sk) AS store_sk,
        COALESCE(s.sales_amount, 0) AS sales_amount,
        COALESCE(r.return_amount, 0) AS return_amount,
        (COALESCE(s.sales_amount, 0) - COALESCE(r.return_amount, 0)) AS net_revenue,
        COALESCE(s.sales_cnt, 0) AS sales_cnt,
        COALESCE(r.return_cnt, 0) AS return_cnt,
        COALESCE(s.distinct_buy_potential_cnt, 0) AS distinct_buy_potential_cnt,
        COALESCE(s.avg_vehicle_count, 0) AS avg_vehicle_count
    FROM sales_item s
    FULL OUTER JOIN returns_item r
        ON s.ss_item_sk = r.sr_item_sk
        AND s.ss_store_sk = r.sr_store_sk
),
customer_store_top AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY COUNT(*) DESC) AS rn
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY ss.ss_store_sk, cd.cd_credit_rating
)
SELECT
    ic.store_sk,
    ic.item_sk,
    ic.sales_amount,
    ic.return_amount,
    ic.net_revenue,
    CASE
        WHEN ic.net_revenue >= 50000 THEN 'HIGH_PERFORMER'
        WHEN ic.net_revenue >= 20000 THEN 'MEDIUM_PERFORMER'
        ELSE 'LOW_PERFORMER'
    END AS performance_category,
    RANK() OVER (PARTITION BY ic.store_sk ORDER BY ic.net_revenue DESC) AS store_item_rank,
    ic.sales_cnt,
    ic.return_cnt,
    ic.distinct_buy_potential_cnt,
    ic.avg_vehicle_count,
    cst.cd_credit_rating AS top_credit_rating
FROM item_combined ic
LEFT JOIN (
    SELECT store_sk, cd_credit_rating
    FROM customer_store_top
    WHERE rn = 1
) cst
    ON ic.store_sk = cst.store_sk
WHERE ic.net_revenue IS NOT NULL
ORDER BY ic.store_sk, store_item_rank
LIMIT 200
