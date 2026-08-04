WITH base AS (
    SELECT
        i.i_manufact,
        i.i_class,
        r.r_reason_desc,
        sm.sm_type,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01'
      AND i.i_rec_end_date <= DATE '2001-12-31'
      AND sm.sm_type = 'EXPRESS'
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY i.i_manufact, i.i_class, r.r_reason_desc, sm.sm_type
)
SELECT
    b.i_manufact,
    b.i_class,
    SUM(b.catalog_net_loss) AS total_catalog_loss,
    SUM(b.store_net_loss) AS total_store_loss,
    (SUM(b.catalog_net_loss) + SUM(b.store_net_loss)) / NULLIF(COUNT(*), 0) AS avg_loss_per_group,
    (SELECT COUNT(*) FROM customer WHERE c_birth_day = 11) AS customers_birth_day_11
FROM base b
WHERE b.catalog_net_loss > 1000
  AND b.store_net_loss > 500
  AND b.i_class IN (
        SELECT i_sub.i_class FROM item i_sub WHERE i_sub.i_category = 'clothing'
        INTERSECT
        SELECT i2_sub.i_class FROM item i2_sub WHERE i2_sub.i_color = 'red'
      )
GROUP BY b.i_manufact, b.i_class
ORDER BY total_catalog_loss DESC
LIMIT 100
