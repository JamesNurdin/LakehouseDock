WITH catalog_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        COUNT(DISTINCT cr.cr_item_sk) AS catalog_distinct_items,
        SUM(cr.cr_return_tax) AS catalog_return_tax
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
),
store_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_store_sk AS store_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        COUNT(DISTINCT sr.sr_item_sk) AS store_distinct_items,
        SUM(sr.sr_return_tax) AS store_return_tax
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
)
SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_state,
    s.s_market_desc,
    ca.catalog_net_loss,
    ca.catalog_return_qty,
    ca.catalog_distinct_items,
    sa.store_net_loss,
    sa.store_return_qty,
    sa.store_distinct_items,
    ws.web_name,
    ws.web_state,
    ws.web_tax_percentage,
    ws.web_mkt_desc,
    d_store.d_year AS store_closed_year,
    d_store.d_date AS store_closed_date,
    d_web_close.d_year AS web_close_year,
    d_web_close.d_date AS web_close_date,
    CASE
        WHEN ca.catalog_net_loss = 0 THEN NULL
        ELSE sa.store_net_loss / ca.catalog_net_loss
    END AS store_to_catalog_loss_ratio,
    (COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0)) AS total_net_loss,
    (COALESCE(ca.catalog_return_tax, 0) + COALESCE(sa.store_return_tax, 0))
        / NULLIF((ca.catalog_return_qty + sa.store_return_qty), 0) AS avg_tax_per_return
FROM date_dim d_ret
LEFT JOIN catalog_agg ca ON ca.date_sk = d_ret.d_date_sk
LEFT JOIN store_agg sa ON sa.date_sk = d_ret.d_date_sk
LEFT JOIN store s ON s.s_store_sk = sa.store_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
LEFT JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
ORDER BY d_ret.d_date DESC
LIMIT 100
