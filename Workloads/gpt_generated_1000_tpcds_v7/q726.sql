WITH joined AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cs.cs_net_paid,
        cs.cs_ext_wholesale_cost,
        cs.cs_quantity,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        r.r_reason_desc,
        ss.ss_quantity AS store_quantity
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cs.cs_ext_wholesale_cost > 3000
      AND cd.cd_gender = 'F'
      AND i.i_category = 'Electronics'
)
SELECT
    i_item_id,
    i_brand,
    i_category,
    cd_gender,
    r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_amount) AS avg_return_amount,
    SUM(cs_net_paid) AS total_sales_net_paid,
    SUM(store_quantity) AS total_store_quantity,
    RANK() OVER (ORDER BY SUM(cr_return_amount) DESC) AS return_amount_rank
FROM joined
GROUP BY i_item_id, i_brand, i_category, cd_gender, r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
