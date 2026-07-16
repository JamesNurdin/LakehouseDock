WITH store_yearly AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_current_month,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, d.d_year, d.d_current_month
),
category_stats AS (
    SELECT
        s.s_state,
        d.d_year,
        d.d_current_month,
        i.i_category,
        i.i_brand,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        COUNT(*) AS cat_returns,
        AVG(cr.cr_return_amount) AS cat_avg_return_amount,
        SUM(cr.cr_refunded_cash + cr.cr_store_credit) AS cat_refunded_total
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY s.s_state, d.d_year, d.d_current_month, i.i_category, i.i_brand
)
SELECT
    cs.s_state,
    cs.d_year,
    cs.d_current_month,
    cs.i_category,
    cs.i_brand,
    cs.cat_net_loss,
    cs.cat_returns,
    cs.cat_avg_return_amount,
    cs.cat_refunded_total,
    sy.total_net_loss,
    sy.total_returns,
    sy.avg_return_amount,
    RANK() OVER (PARTITION BY cs.s_state, cs.d_year, cs.d_current_month
                 ORDER BY cs.cat_net_loss DESC) AS cat_loss_rank
FROM category_stats cs
JOIN store_yearly sy
    ON cs.s_state = sy.s_state
   AND cs.d_year = sy.d_year
   AND cs.d_current_month = sy.d_current_month
ORDER BY cs.s_state, cs.d_year, cs.d_current_month, cat_loss_rank
