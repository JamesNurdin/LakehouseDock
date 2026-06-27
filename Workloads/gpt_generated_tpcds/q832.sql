WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_store_sk, i.i_category, p.p_promo_name
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        i.i_category AS category,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_return_transactions
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_store_sk, i.i_category
),
 demo_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        i.i_category AS category,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ss.ss_store_sk, i.i_category
)
SELECT
    s.s_store_name,
    sa.category,
    COALESCE(sa.promo_name, 'No Promo') AS promo_name,
    sa.total_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    (sa.total_sales - COALESCE(ra.total_returns, 0)) AS net_sales,
    sa.total_profit - COALESCE(ra.total_return_loss, 0) AS net_profit,
    sa.num_transactions,
    COALESCE(ra.num_return_transactions, 0) AS num_return_transactions,
    da.avg_purchase_estimate,
    da.avg_vehicle_count
FROM sales_agg sa
JOIN store s
    ON sa.store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON ra.store_sk = sa.store_sk
    AND ra.category = sa.category
LEFT JOIN demo_agg da
    ON da.store_sk = sa.store_sk
    AND da.category = sa.category
ORDER BY net_sales DESC
LIMIT 100
