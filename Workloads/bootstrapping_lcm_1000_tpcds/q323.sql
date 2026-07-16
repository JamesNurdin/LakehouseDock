WITH returns_detail AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        s.s_market_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
), agg_returns AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        refunded_gender,
        returning_gender,
        s_market_desc,
        COUNT(*) AS num_returns,
        SUM(cr_return_quantity) AS total_quantity,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(CASE WHEN cr_return_amount > 100 THEN cr_return_amount ELSE 0 END) AS high_value_return_amount,
        approx_percentile(cr_return_amount, 0.5) AS median_return_amount
    FROM returns_detail
    GROUP BY
        d_year,
        d_month_seq,
        i_category,
        refunded_gender,
        returning_gender,
        s_market_desc
    HAVING SUM(cr_return_amount) > 0
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    refunded_gender,
    returning_gender,
    s_market_desc,
    num_returns,
    total_quantity,
    total_return_amount,
    total_net_loss,
    avg_return_amount,
    high_value_return_amount,
    median_return_amount,
    ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY total_net_loss DESC) AS loss_rank_within_year_category
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100
