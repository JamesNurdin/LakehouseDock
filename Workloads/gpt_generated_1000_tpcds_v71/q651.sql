WITH cat_agg AS (
    SELECT
        cr_returned_date_sk,
        SUM(cr_net_loss) AS cat_net_loss,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns
    WHERE cr_return_quantity > 5
      AND cr_reversed_charge > 20
      AND cr_fee < 100
    GROUP BY cr_returned_date_sk
),
store_agg AS (
    SELECT
        sr_returned_date_sk,
        SUM(sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    WHERE sr_fee > 60
      AND sr_return_ship_cost > 20
      AND sr_return_quantity > 0
    GROUP BY sr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    cat_agg.cat_net_loss,
    cat_agg.cat_return_cnt,
    store_agg.store_net_loss,
    store_agg.store_return_cnt,
    RANK() OVER (PARTITION BY d.d_year ORDER BY (cat_agg.cat_net_loss + store_agg.store_net_loss) DESC) AS loss_rank
FROM cat_agg
JOIN date_dim d
    ON cat_agg.cr_returned_date_sk = d.d_date_sk
JOIN store_agg
    ON store_agg.sr_returned_date_sk = d.d_date_sk
WHERE d.d_current_day = 'N'
  AND d.d_following_holiday = 'N'
  AND d.d_year = 2001
ORDER BY loss_rank
LIMIT 100
