WITH agg AS (
    SELECT
        d.d_year,
        i.i_brand,
        i.i_category,
        s.s_state,
        s.s_market_id,
        sum(cr.cr_return_amount) AS total_return_amount,
        sum(cr.cr_net_loss) AS total_net_loss,
        avg(cr.cr_return_quantity) AS avg_return_quantity,
        count(*) AS return_count,
        sum(CASE WHEN hd_ref.hd_income_band_sk <> hd_ret.hd_income_band_sk THEN 1 ELSE 0 END) AS mismatched_income_band_returns,
        sum(cr.cr_fee) AS total_fee,
        sum(cr.cr_store_credit) AS total_store_credit,
        sum(cr.cr_return_tax) AS total_return_tax,
        avg(i.i_current_price - i.i_wholesale_cost) AS avg_gross_margin,
        avg(s.s_tax_percentage) AS avg_store_tax_percentage,
        sum(s.s_floor_space) AS total_floor_space
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY d.d_year, i.i_brand, i.i_category, s.s_state, s.s_market_id
    HAVING sum(cr.cr_return_amount) > 1000
)
SELECT
    a.d_year,
    a.i_brand,
    a.i_category,
    a.s_state,
    a.s_market_id,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_quantity,
    a.return_count,
    a.mismatched_income_band_returns,
    a.total_fee,
    a.total_store_credit,
    a.total_return_tax,
    a.avg_gross_margin,
    a.avg_store_tax_percentage,
    a.total_floor_space,
    a.total_return_amount / sum(a.total_return_amount) OVER (PARTITION BY a.d_year) AS pct_of_year_return_amount
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
