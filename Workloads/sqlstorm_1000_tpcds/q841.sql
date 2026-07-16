WITH daily_store_sales AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk
),
daily_store_returns AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_store_sk AS store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS ret_txn_count
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
),
daily_store_sales_full AS (
    SELECT
        COALESCE(ds.date_sk, dr.date_sk) AS date_sk,
        COALESCE(ds.store_sk, dr.store_sk) AS store_sk,
        COALESCE(ds.total_sales, 0) - COALESCE(dr.total_returns, 0) AS net_sales,
        COALESCE(ds.total_profit, 0) - COALESCE(dr.total_loss, 0) AS net_profit,
        COALESCE(ds.txn_count, 0) AS sales_txn,
        COALESCE(dr.ret_txn_count, 0) AS return_txn
    FROM daily_store_sales ds
    FULL OUTER JOIN daily_store_returns dr
        ON ds.date_sk = dr.date_sk AND ds.store_sk = dr.store_sk
),
daily_web_sales AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        CAST(NULL AS integer) AS store_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
combined_sales AS (
    SELECT
        date_sk,
        store_sk,
        net_sales,
        net_profit,
        sales_txn,
        return_txn
    FROM daily_store_sales_full
    UNION ALL
    SELECT
        date_sk,
        store_sk,
        total_sales AS net_sales,
        total_profit AS net_profit,
        txn_count AS sales_txn,
        0 AS return_txn
    FROM daily_web_sales
),
high_sales_dates AS (
    SELECT date_sk
    FROM daily_store_sales_full
    WHERE net_sales > 10000
    INTERSECT
    SELECT date_sk
    FROM daily_web_sales
    WHERE total_sales > 5000
),
store_details AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_gmt_offset,
        s.s_tax_percentage
    FROM store s
),
store_ranked AS (
    SELECT
        cs.date_sk,
        cs.store_sk,
        sd.s_store_name,
        sd.s_city,
        sd.s_state,
        cs.net_sales,
        cs.net_profit,
        sd.s_gmt_offset,
        sd.s_tax_percentage,
        ROW_NUMBER() OVER (PARTITION BY cs.date_sk ORDER BY cs.net_sales DESC) AS sales_rank,
        AVG(cs.net_sales) OVER (PARTITION BY sd.s_state) AS avg_state_sales,
        (cs.net_sales - AVG(cs.net_sales) OVER (PARTITION BY sd.s_state)) / NULLIF(AVG(cs.net_sales) OVER (PARTITION BY sd.s_state), 0) AS sales_vs_state_avg_ratio
    FROM combined_sales cs
    LEFT JOIN store_details sd ON cs.store_sk = sd.s_store_sk
    WHERE cs.net_sales > 0
),
promo_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_promo_sk AS promo_sk,
        SUM(cs.cs_ext_sales_price) AS promo_sales,
        COUNT(*) AS promo_txns
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_sold_date_sk, cs.cs_promo_sk
),
promo_details AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_tv,
        p.p_channel_email,
        CONCAT(COALESCE(p.p_promo_name, ''), ' ', COALESCE(p.p_channel_tv, ''), ' ', COALESCE(p.p_channel_email, '')) AS promo_desc
    FROM promotion p
),
top_promo_by_day AS (
    SELECT
        ps.date_sk,
        pd.p_promo_sk,
        pd.promo_desc,
        ps.promo_sales,
        ROW_NUMBER() OVER (PARTITION BY ps.date_sk ORDER BY ps.promo_sales DESC) AS promo_rank
    FROM promo_sales ps
    JOIN promo_details pd ON ps.promo_sk = pd.p_promo_sk
),
final_stats AS (
    SELECT
        sr.date_sk,
        sr.sales_rank,
        sr.s_store_name,
        sr.s_city,
        sr.s_state,
        sr.net_sales,
        sr.net_profit,
        sr.sales_vs_state_avg_ratio,
        tp.promo_desc,
        tp.promo_sales,
        sr.sales_rank * (tp.promo_sales / NULLIF(sr.net_sales, 0)) AS weighted_score,
        (SELECT COUNT(*) FROM store_ranked sr2 WHERE sr2.s_state = sr.s_state AND sr2.sales_rank <= sr.sales_rank) AS rank_position_in_state,
        CASE
            WHEN sr.sales_rank = 1 THEN 'TOP'
            WHEN sr.sales_rank <= 5 THEN 'TOP5'
            ELSE 'OTHER'
        END AS rank_category,
        COALESCE(sr.net_sales, 0) + COALESCE(tp.promo_sales, 0) AS combined_revenue
    FROM store_ranked sr
    LEFT JOIN top_promo_by_day tp ON sr.date_sk = tp.date_sk AND tp.promo_rank = 1
    WHERE sr.sales_rank <= 10
      AND sr.date_sk IN (SELECT date_sk FROM high_sales_dates)
)
SELECT
    f.date_sk,
    d.d_date AS sale_date,
    f.s_store_name,
    f.s_city,
    f.s_state,
    f.sales_rank,
    f.rank_category,
    f.net_sales,
    f.net_profit,
    f.sales_vs_state_avg_ratio,
    f.promo_desc,
    f.promo_sales,
    f.weighted_score,
    f.rank_position_in_state,
    f.combined_revenue,
    CASE
        WHEN f.combined_revenue > (SELECT AVG(combined_revenue) FROM final_stats) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS revenue_classification,
    CONCAT(f.s_store_name, ' - ', COALESCE(f.promo_desc, 'No Promo')) AS full_description,
    COALESCE(f.net_sales, 0) / NULLIF(f.sales_rank, 0) AS avg_sales_per_rank
FROM final_stats f
JOIN date_dim d ON f.date_sk = d.d_date_sk
WHERE f.combined_revenue IS NOT NULL
ORDER BY f.date_sk DESC, f.sales_rank ASC
LIMIT 100
