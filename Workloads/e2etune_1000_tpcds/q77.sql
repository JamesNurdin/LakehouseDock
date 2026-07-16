WITH all_returns AS (
    SELECT 
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_amt_inc_tax AS return_amount_inc_tax,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_tax AS return_tax,
        cr.cr_reason_sk AS reason_sk,
        cd.cd_education_status AS education_status,
        cd.cd_gender AS gender,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_time_sk IN (49726, 44830, 73428)
),
web_ret AS (
    SELECT 
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_amt_inc_tax AS return_amount_inc_tax,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_tax AS return_tax,
        wr.wr_reason_sk AS reason_sk,
        cd.cd_education_status AS education_status,
        cd.cd_gender AS gender,
        'web' AS channel
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_time_sk IN (49726, 44830, 73428)
),
joined_returns AS (
    SELECT 
        ar.returned_date_sk,
        i.i_category,
        i.i_category_id,
        r.r_reason_desc,
        ar.channel,
        SUM(ar.return_amount_inc_tax) AS total_return_inc_tax,
        SUM(ar.return_quantity) AS total_quantity,
        AVG(ar.return_tax) AS avg_tax,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN ar.education_status = 'Graduate' THEN 1 ELSE 0 END) AS grad_edu_cnt
    FROM all_returns ar
    JOIN item i ON ar.item_sk = i.i_item_sk
    JOIN reason r ON ar.reason_sk = r.r_reason_sk
    GROUP BY 
        ar.returned_date_sk,
        i.i_category,
        i.i_category_id,
        r.r_reason_desc,
        ar.channel
)
SELECT 
    returned_date_sk,
    i_category,
    r_reason_desc,
    channel,
    total_return_inc_tax,
    total_quantity,
    avg_tax,
    cnt_returns,
    grad_edu_cnt,
    (grad_edu_cnt * 100.0 / cnt_returns) AS pct_grad_edu
FROM joined_returns
WHERE cnt_returns > 10
ORDER BY total_return_inc_tax DESC
LIMIT 100
