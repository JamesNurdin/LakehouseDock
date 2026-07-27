WITH per_return AS (
    SELECT
        i.i_brand_id AS brand_id,
        i.i_category AS category,
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(sr.sr_return_quantity) AS store_qty,
        SUM(sr.sr_return_amt) AS store_amt,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(wr.wr_return_quantity) AS web_qty,
        SUM(wr.wr_return_amt) AS web_amt,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        sr.sr_return_quantity > 10
        AND sr.sr_fee > 30
        AND sr.sr_store_credit < 500
        AND wr.wr_return_quantity BETWEEN 20 AND 60
        AND wr.wr_return_tax > 20
        AND i.i_brand_id IN (3003001, 1001001, 6016006)
    GROUP BY i.i_brand_id, i.i_category, cd.cd_gender, cd.cd_education_status
)
SELECT
    brand_id,
    category,
    gender,
    education_status,
    store_qty,
    web_qty,
    (store_amt + web_amt) AS total_return_amount,
    (store_net_loss + web_net_loss) AS total_net_loss,
    CASE
        WHEN (store_qty + web_qty) > 0 THEN (store_net_loss + web_net_loss) / (store_qty + web_qty)
        ELSE NULL
    END AS avg_loss_per_item
FROM per_return
WHERE EXISTS (
    SELECT 1
    FROM item i2
    WHERE i2.i_item_sk = (
        SELECT MAX(sr2.sr_item_sk)
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 0
    )
    AND i2.i_category = per_return.category
)
ORDER BY total_net_loss DESC
LIMIT 100
