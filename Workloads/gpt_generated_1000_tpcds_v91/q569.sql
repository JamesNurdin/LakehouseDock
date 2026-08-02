WITH returns_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        cr_returning_cdemo_sk,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        SUM(cr_return_quantity) AS total_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_fee > 5.00
      AND cr_store_credit > 20.00
      AND cr_call_center_sk IN (7, 13, 19)
    GROUP BY cr_item_sk, cr_returned_date_sk, cr_returning_cdemo_sk
),
year_gender_agg AS (
    SELECT
        d.d_year AS d_year,
        cd.cd_gender AS cd_gender,
        SUM(ra.total_net_loss) AS sum_net_loss,
        AVG(ra.total_net_loss) AS avg_net_loss,
        COUNT(*) AS cnt_items
    FROM returns_agg ra
    INNER JOIN date_dim d
        ON ra.cr_returned_date_sk = d.d_date_sk
    INNER JOIN customer_demographics cd
        ON ra.cr_returning_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    cd.cd_gender,
    cd.cd_marital_status,
    ra.total_net_loss,
    CASE
        WHEN ra.total_net_loss > 1000 THEN 'HIGH_LOSS'
        WHEN ra.total_net_loss BETWEEN 500 AND 1000 THEN 'MEDIUM_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ra.total_net_loss DESC) AS loss_rank_year,
    yg.sum_net_loss,
    yg.avg_net_loss,
    yg.cnt_items
FROM returns_agg ra
RIGHT OUTER JOIN item i
    ON ra.cr_item_sk = i.i_item_sk
INNER JOIN date_dim d
    ON ra.cr_returned_date_sk = d.d_date_sk
INNER JOIN customer_demographics cd
    ON ra.cr_returning_cdemo_sk = cd.cd_demo_sk
LEFT JOIN year_gender_agg yg
    ON d.d_year = yg.d_year AND cd.cd_gender = yg.cd_gender
WHERE i.i_class_id IN (3, 11, 12)
  AND d.d_year BETWEEN 2001 AND 2002
  AND cd.cd_gender = 'M'
ORDER BY d.d_year, loss_rank_year
LIMIT 100
