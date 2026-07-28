WITH base AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_order_number,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_addr_sk,
        wr.wr_item_sk,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_order_number,
        wr.wr_reason_sk,
        i.i_category,
        i.i_brand,
        r_cr.r_reason_desc,
        sm.sm_code,
        ca_ref.ca_state
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN customer_address ca_ref_wr ON wr.wr_refunded_addr_sk = ca_ref_wr.ca_address_sk
    LEFT JOIN customer_demographics cd_ref_wr ON wr.wr_refunded_cdemo_sk = cd_ref_wr.cd_demo_sk
)
SELECT
    i_category,
    r_reason_desc,
    SUM(cr_net_loss + wr_net_loss) AS total_loss,
    COUNT(DISTINCT cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT wr_order_number) AS web_order_cnt,
    AVG(cr_return_amount) AS avg_catalog_return_amount,
    AVG(wr_return_amt) AS avg_web_return_amount,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(cr_net_loss + wr_net_loss) DESC) AS loss_rank,
    CASE
        WHEN SUM(cr_net_loss + wr_net_loss) > (SELECT AVG(cr_net_loss) FROM catalog_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_vs_catalog_avg
FROM base
WHERE
    i_brand = 'BrandX' AND
    sm_code = 'AIR' AND
    ca_state = 'CA' AND
    r_reason_desc LIKE '%damaged%' AND
    cr_return_quantity > 1 AND
    wr_return_quantity > 0 AND
    cr_return_amount > 10
GROUP BY ROLLUP (i_category, r_reason_desc)
ORDER BY total_loss DESC
LIMIT 100
