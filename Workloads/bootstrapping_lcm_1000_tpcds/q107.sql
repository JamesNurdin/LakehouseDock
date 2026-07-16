WITH agg AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_catalog_items,
        COUNT(DISTINCT wr.wr_item_sk) AS distinct_web_items,
        AVG(cr.cr_net_loss) AS avg_catalog_net_loss,
        AVG(wr.wr_net_loss) AS avg_web_net_loss,
        SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_quantity ELSE 0 END) AS high_qty_catalog_returns,
        SUM(CASE WHEN wr.wr_return_quantity > 5 THEN wr.wr_return_quantity ELSE 0 END) AS high_qty_web_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_return_amount + total_web_return_amount DESC) AS rank_in_year
    FROM agg
)
SELECT
    d_year,
    d_month_seq,
    store_name,
    store_city,
    store_state,
    total_catalog_return_amount,
    total_web_return_amount,
    total_catalog_return_amount + total_web_return_amount AS total_return_amount,
    distinct_catalog_items,
    distinct_web_items,
    avg_catalog_net_loss,
    avg_web_net_loss,
    high_qty_catalog_returns,
    high_qty_web_returns,
    rank_in_year
FROM ranked
WHERE rank_in_year <= 5
ORDER BY d_year, rank_in_year
