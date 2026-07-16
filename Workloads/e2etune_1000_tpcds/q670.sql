WITH cat_agg AS (
    SELECT
        cr_item_sk AS item_sk,
        cr_returned_date_sk AS date_sk,
        SUM(cr_return_amount) AS sum_cr_return_amount,
        SUM(cr_net_loss) AS sum_cr_net_loss,
        COUNT(*) AS cnt_cr
    FROM catalog_returns
    WHERE cr_fee > 20
      AND cr_warehouse_sk IN (1, 12, 13)
      AND cr_return_amount > 0
    GROUP BY cr_item_sk, cr_returned_date_sk
),
store_agg AS (
    SELECT
        sr_item_sk AS item_sk,
        sr_returned_date_sk AS date_sk,
        sr_store_sk AS store_sk,
        SUM(sr_return_amt_inc_tax) AS sum_sr_return_amount,
        SUM(sr_net_loss) AS sum_sr_net_loss,
        COUNT(*) AS cnt_sr
    FROM store_returns
    WHERE sr_fee > 20
      AND sr_return_amt_inc_tax > 0
    GROUP BY sr_item_sk, sr_returned_date_sk, sr_store_sk
),
joined_returns AS (
    SELECT
        ca.item_sk,
        ca.date_sk,
        ca.sum_cr_return_amount,
        ca.sum_cr_net_loss,
        ca.cnt_cr,
        sa.store_sk,
        sa.sum_sr_return_amount,
        sa.sum_sr_net_loss,
        sa.cnt_sr
    FROM cat_agg ca
    JOIN store_agg sa
      ON ca.item_sk = sa.item_sk
     AND ca.date_sk = sa.date_sk
    WHERE (ca.sum_cr_return_amount + sa.sum_sr_return_amount) > 500
)
SELECT
    jr.item_sk,
    jr.date_sk,
    jr.store_sk,
    ws.web_name,
    ws.web_city,
    jr.sum_cr_return_amount,
    jr.sum_sr_return_amount,
    (jr.sum_cr_return_amount + jr.sum_sr_return_amount) AS total_return_amount,
    (jr.sum_cr_net_loss + jr.sum_sr_net_loss) AS total_net_loss,
    (jr.cnt_cr + jr.cnt_sr) AS total_returns,
    ((jr.sum_cr_net_loss + jr.sum_sr_net_loss) / NULLIF((jr.sum_cr_return_amount + jr.sum_sr_return_amount), 0)) AS loss_ratio,
    RANK() OVER (PARTITION BY jr.date_sk ORDER BY ((jr.sum_cr_net_loss + jr.sum_sr_net_loss) / NULLIF((jr.sum_cr_return_amount + jr.sum_sr_return_amount), 0)) DESC) AS loss_rank
FROM joined_returns jr
LEFT JOIN web_site ws
  ON jr.store_sk = ws.web_site_sk
WHERE (jr.sum_cr_return_amount + jr.sum_sr_return_amount) > 1000
ORDER BY jr.date_sk, loss_rank
LIMIT 100
