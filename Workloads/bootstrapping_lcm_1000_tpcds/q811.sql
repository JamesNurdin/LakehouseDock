WITH cat_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        COUNT(*) AS cat_return_cnt,
        SUM(cr.cr_return_quantity) AS cat_return_qty,
        SUM(cr.cr_return_amount) AS cat_return_amt,
        SUM(cr.cr_net_loss) AS cat_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
),
web_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
store_agg AS (
    SELECT
        s.s_closed_date_sk,
        COUNT(*) AS closed_store_cnt,
        MAX(s.s_store_name) AS any_store_name
    FROM store s
    GROUP BY s.s_closed_date_sk
),
combined_agg AS (
    SELECT
        COALESCE(ca.cr_returned_date_sk, wa.wr_returned_date_sk) AS date_sk,
        COALESCE(ca.cr_item_sk, wa.wr_item_sk) AS item_sk,
        COALESCE(ca.cat_return_cnt, 0) AS cat_return_cnt,
        COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
        COALESCE(ca.cat_return_qty, 0) AS cat_return_qty,
        COALESCE(wa.web_return_qty, 0) AS web_return_qty,
        COALESCE(ca.cat_return_amt, 0) AS cat_return_amt,
        COALESCE(wa.web_return_amt, 0) AS web_return_amt,
        COALESCE(ca.cat_net_loss, 0) AS cat_net_loss,
        COALESCE(wa.web_net_loss, 0) AS web_net_loss
    FROM cat_agg ca
    FULL OUTER JOIN web_agg wa
        ON ca.cr_returned_date_sk = wa.wr_returned_date_sk
        AND ca.cr_item_sk = wa.wr_item_sk
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    agg.cat_return_cnt,
    agg.web_return_cnt,
    (agg.cat_return_qty + agg.web_return_qty) AS total_return_quantity,
    (agg.cat_return_amt + agg.web_return_amt) AS total_return_amount,
    (agg.cat_net_loss + agg.web_net_loss) AS total_net_loss,
    COALESCE(sa.closed_store_cnt, 0) AS closed_store_count,
    sa.any_store_name,
    CASE WHEN agg.web_return_cnt > 0 THEN agg.cat_return_cnt * 1.0 / agg.web_return_cnt ELSE NULL END AS cat_to_web_return_ratio,
    CASE WHEN (agg.cat_return_cnt + agg.web_return_cnt) > 0 THEN (agg.cat_return_amt + agg.web_return_amt) / (agg.cat_return_cnt + agg.web_return_cnt) ELSE NULL END AS avg_return_amount_per_return,
    ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY (agg.cat_return_amt + agg.web_return_amt) DESC) AS rank_by_return_amount
FROM date_dim d
LEFT JOIN combined_agg agg ON agg.date_sk = d.d_date_sk
LEFT JOIN item i ON i.i_item_sk = agg.item_sk
LEFT JOIN store_agg sa ON sa.s_closed_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
ORDER BY d.d_date DESC, total_return_amount DESC
LIMIT 200
