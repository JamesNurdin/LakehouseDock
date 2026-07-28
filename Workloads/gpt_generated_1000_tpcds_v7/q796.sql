WITH returns_enriched AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_store_credit,
        cr.cr_refunded_cash,
        cr.cr_return_quantity,
        d.d_year,
        d.d_date,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        cc.cc_sq_ft
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 1998
      AND cc.cc_state = 'CA'
      AND cr.cr_return_amount > 100
      AND cc.cc_sq_ft > 0
      AND cr.cr_refunded_cash > 0
)
SELECT
    re.d_year,
    re.cc_call_center_id,
    re.cc_name,
    SUM(re.cr_net_loss) AS total_net_loss,
    SUM(re.cr_store_credit) AS total_store_credit,
    ROW_NUMBER() OVER (PARTITION BY re.d_year ORDER BY SUM(re.cr_net_loss) DESC) AS loss_rank,
    RANK() OVER (PARTITION BY re.d_year ORDER BY SUM(re.cr_store_credit) DESC) AS credit_rank,
    CASE WHEN SUM(re.cr_net_loss) > 5000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
FROM returns_enriched re
GROUP BY
    re.d_year,
    re.cc_call_center_id,
    re.cc_name
ORDER BY re.d_year, loss_rank
LIMIT 100
