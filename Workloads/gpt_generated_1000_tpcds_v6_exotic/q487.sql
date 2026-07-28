WITH unified_returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk,
        i.i_current_price,
        r.r_reason_desc,
        cd.cd_gender,
        ca.ca_state,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_qty,
        CASE WHEN i.i_color = 'red' THEN 'Red' ELSE 'Other' END AS color_group
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_return_quantity >= 2
      AND i.i_current_price > 50
      AND ca.ca_state = 'CA'
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk,
        i.i_current_price,
        r.r_reason_desc,
        cd.cd_gender,
        ca.ca_state,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS return_qty,
        CASE WHEN i.i_color = 'red' THEN 'Red' ELSE 'Other' END AS color_group
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_amt > 500
      AND wr.wr_return_quantity >= 1
      AND i.i_current_price > 50
      AND ca.ca_state = 'CA'
),
per_group AS (
    SELECT
        cr_item_sk AS i_item_sk,
        r_reason_desc,
        cd_gender,
        color_group,
        SUM(return_amount) AS total_return_amount,
        AVG(return_qty) AS avg_return_qty,
        COUNT(*) AS txn_cnt
    FROM unified_returns
    GROUP BY cr_item_sk, r_reason_desc, cd_gender, color_group
)
SELECT
    i_item_sk,
    r_reason_desc,
    cd_gender,
    color_group,
    total_return_amount,
    avg_return_qty,
    txn_cnt,
    SUM(total_return_amount) OVER (PARTITION BY cd_gender) AS gender_total_return,
    RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank
FROM per_group
WHERE total_return_amount > 2000
ORDER BY total_return_amount DESC
LIMIT 100
