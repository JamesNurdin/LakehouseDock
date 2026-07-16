WITH returns_with_demo AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_customer_sk,
        cd_ref.cd_gender AS refunded_gender,
        cd_ref.cd_education_status AS refunded_education,
        cd_ret.cd_gender AS returning_gender,
        cd_ret.cd_education_status AS returning_education
    FROM catalog_returns cr
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
),
aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT r.cr_order_number) AS num_returns,
        SUM(r.cr_return_amount) AS total_return_amount,
        SUM(r.cr_net_loss) AS total_net_loss,
        AVG(r.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT r.cr_returning_customer_sk) AS distinct_returning_customers,
        SUM(p_start.p_cost) AS total_promo_start_cost,
        SUM(p_end.p_cost) AS total_promo_end_cost,
        CASE
            WHEN MAX(p_start.p_discount_active) = 'Y' OR MAX(p_end.p_discount_active) = 'Y' THEN 'Y'
            ELSE 'N'
        END AS any_discount_active
    FROM returns_with_demo r
    JOIN date_dim d
        ON r.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p_start
        ON p_start.p_start_date_sk = d.d_date_sk
    JOIN promotion p_end
        ON p_end.p_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
        AND s.s_state = 'CA'
        AND (p_start.p_discount_active = 'Y' OR p_end.p_discount_active = 'Y')
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq
    HAVING SUM(r.cr_return_amount) > 1000
)
SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
