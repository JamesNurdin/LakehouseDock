WITH sampled_store AS (
    SELECT
        s_store_sk,
        s_store_id,
        s_manager,
        s_city,
        s_state,
        s_rec_end_date,
        s_tax_percentage
    FROM store
    TABLESAMPLE BERNOULLI (10)
    WHERE s_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND s_manager IN ('Joe Johnson', 'Jerry Brooks')
      AND s_state = 'CA'
),
store_return_full AS (
    SELECT
        s.s_store_sk,
        s.s_manager,
        s.s_city,
        sr.sr_return_tax,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        CASE WHEN sr.sr_return_tax > 5 THEN 'high_tax' ELSE 'low_tax' END AS tax_category,
        t.t_shift,
        t.t_minute
    FROM sampled_store s
    FULL OUTER JOIN store_returns sr
        ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE (t.t_shift IS NULL OR t.t_shift = 'first')
      AND (t.t_minute IS NULL OR t.t_minute > 5)
      AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
),
agg_by_store AS (
    SELECT
        s_store_sk,
        s_manager,
        s_city,
        tax_category,
        COUNT(*) AS return_cnt,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(sr_return_tax) AS avg_return_tax
    FROM store_return_full
    WHERE sr_net_loss IS NOT NULL
    GROUP BY s_store_sk, s_manager, s_city, tax_category
),
final_agg AS (
    SELECT
        s_manager,
        tax_category,
        SUM(return_cnt) AS total_returns,
        AVG(total_net_loss) AS avg_loss_per_store,
        AVG(avg_return_tax) AS avg_tax
    FROM agg_by_store
    GROUP BY s_manager, tax_category
    HAVING SUM(return_cnt) > 5
)
SELECT
    s_manager,
    tax_category,
    total_returns,
    avg_loss_per_store,
    avg_tax
FROM final_agg
EXCEPT
SELECT
    s_manager,
    tax_category,
    total_returns,
    avg_loss_per_store,
    avg_tax
FROM (
    SELECT
        s_manager,
        tax_category,
        SUM(return_cnt) AS total_returns,
        AVG(total_net_loss) AS avg_loss_per_store,
        AVG(avg_return_tax) AS avg_tax
    FROM agg_by_store
    GROUP BY s_manager, tax_category
    HAVING SUM(return_cnt) <= 5
) low_volume
ORDER BY s_manager, tax_category
