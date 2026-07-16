WITH aggregated_returns AS (
    SELECT
        cr_order_number,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        MIN(cr_returned_date_sk) AS min_returned_date_sk,
        MAX(cr_returned_date_sk) AS max_returned_date_sk,
        MIN(cr_refunded_cdemo_sk) AS any_refunded_cdemo_sk,
        MIN(cr_returning_cdemo_sk) AS any_returning_cdemo_sk
    FROM catalog_returns
    GROUP BY cr_order_number
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    ar.cr_order_number,
    ar.total_return_qty,
    ar.total_return_amount,
    ar.total_net_loss,
    d_ret.d_date AS return_date,
    d_ret.d_year,
    cd_ref.cd_gender AS refunded_gender,
    cd_ref.cd_marital_status AS refunded_marital_status,
    cd_ret.cd_gender AS returning_gender,
    cd_ret.cd_marital_status AS returning_marital_status,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    CASE
        WHEN ar.total_return_amount > 5000 THEN 'High'
        WHEN ar.total_return_amount > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS return_severity
FROM aggregated_returns ar
JOIN date_dim d_ret
    ON ar.min_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ref
    ON ar.any_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON ar.any_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
ORDER BY ar.total_return_amount DESC
LIMIT 100
