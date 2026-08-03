WITH cr_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cr_agg.total_return_qty,
    cr_agg.total_net_loss,
    CASE WHEN cc.cc_state = 'CA' THEN 'West' ELSE 'Other' END AS region_category,
    (SELECT SUM(wr_sub.wr_net_loss)
     FROM web_returns wr_sub
     WHERE wr_sub.wr_item_sk = i.i_item_sk) AS web_net_loss_total,
    d1.d_year,
    sm.sm_type AS ship_mode_type,
    r1.r_reason_desc AS reason_desc
FROM cr_agg
JOIN (
        SELECT * FROM item TABLESAMPLE BERNOULLI (10)
    ) i
    ON cr_agg.cr_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r1
    ON cr.cr_reason_sk = r1.r_reason_sk
JOIN date_dim d1
    ON cr.cr_returned_date_sk = d1.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
WHERE d1.d_year = 2001
  AND sm.sm_code = 'AIR'
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm2.sm_type = 'EXPRESS'
    )
UNION DISTINCT
SELECT
    i2.i_item_id,
    i2.i_product_name,
    wr.wr_return_quantity AS total_return_qty,
    wr.wr_net_loss AS total_net_loss,
    CASE WHEN cc2.cc_state = 'CA' THEN 'West' ELSE 'Other' END AS region_category,
    (SELECT SUM(wr_sub.wr_net_loss)
     FROM web_returns wr_sub
     WHERE wr_sub.wr_item_sk = i2.i_item_sk) AS web_net_loss_total,
    d2.d_year,
    NULL AS ship_mode_type,
    r2.r_reason_desc AS reason_desc
FROM web_returns wr
JOIN item i2
    ON wr.wr_item_sk = i2.i_item_sk
JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
JOIN date_dim d2
    ON wr.wr_returned_date_sk = d2.d_date_sk
FULL OUTER JOIN call_center cc2
    ON cc2.cc_closed_date_sk = d2.d_date_sk
WHERE d2.d_year BETWEEN 2000 AND 2002
ORDER BY total_net_loss DESC
LIMIT 100
