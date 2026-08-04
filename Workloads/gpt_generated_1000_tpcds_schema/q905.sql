WITH base_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss,
        r.r_reason_desc,
        i.i_item_desc,
        d.d_year,
        d.d_month_seq,
        cr.cr_refunded_cdemo_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)defect|damage')
      AND i.i_item_desc LIKE '%steel%'
),

high_loss_items AS (
    SELECT
        cr_item_sk,
        AVG(cr_net_loss) AS avg_loss
    FROM base_returns
    GROUP BY cr_item_sk
    HAVING AVG(cr_net_loss) > 500
    LIMIT 100
),

promoted_items AS (
    SELECT DISTINCT p.p_item_sk
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
    WHERE d_start.d_year = 2000
      AND p.p_discount_active = 'Y'
),

intersect_items AS (
    SELECT cr_item_sk FROM high_loss_items
    INTERSECT
    SELECT p_item_sk FROM promoted_items
),

agg_by_reason AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS return_cnt,
        SUM(br.cr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(br.cr_net_loss) AS total_loss
    FROM base_returns br
    JOIN reason r ON br.r_reason_desc = r.r_reason_desc
    JOIN intersect_items ii ON br.cr_item_sk = ii.cr_item_sk
    GROUP BY r.r_reason_desc
),

agg_by_customer_demo AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        COUNT(*) AS cnt,
        SUM(br.cr_net_loss) AS loss
    FROM base_returns br
    JOIN customer_demographics cd ON br.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN intersect_items ii ON br.cr_item_sk = ii.cr_item_sk
    GROUP BY cd.cd_gender, cd.cd_education_status
)

SELECT
    reason_desc AS group_key,
    return_cnt,
    total_return_inc_tax,
    total_loss
FROM agg_by_reason
UNION DISTINCT
SELECT
    CONCAT(cd_gender, ':', cd_education_status) AS group_key,
    cnt,
    NULL AS total_return_inc_tax,
    loss AS total_loss
FROM agg_by_customer_demo
ORDER BY total_loss DESC
OFFSET 20 FETCH FIRST 100 ROWS ONLY
