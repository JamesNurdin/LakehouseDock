WITH returns_combined AS (
    SELECT
        cr_returned_date_sk AS return_date_sk,
        cr_item_sk AS item_sk,
        cr_return_amount AS return_amount,
        cr_net_loss AS net_loss,
        cr_return_quantity AS return_quantity,
        cr_returning_hdemo_sk AS returning_hdemo_sk
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk AS return_date_sk,
        wr_item_sk AS item_sk,
        wr_return_amt AS return_amount,
        wr_net_loss AS net_loss,
        wr_return_quantity AS return_quantity,
        wr_returning_hdemo_sk AS returning_hdemo_sk
    FROM web_returns
),
joined_data AS (
    SELECT
        rc.return_date_sk,
        rc.item_sk,
        rc.return_amount,
        rc.net_loss,
        rc.return_quantity,
        rc.returning_hdemo_sk,
        d.d_year,
        d.d_moy,
        i.i_category,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM returns_combined rc
    JOIN date_dim d ON rc.return_date_sk = d.d_date_sk
    JOIN item i ON rc.item_sk = i.i_item_sk
    JOIN household_demographics hd ON rc.returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2022
      AND hd.hd_buy_potential = 'High'
),
aggregated AS (
    SELECT
        i_category,
        d_moy AS month,
        hd_income_band_sk,
        SUM(net_loss) AS total_net_loss,
        SUM(return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        AVG(return_quantity) AS avg_return_quantity
    FROM joined_data
    GROUP BY i_category, d_moy, hd_income_band_sk
    HAVING SUM(net_loss) > 0
),
category_totals AS (
    SELECT
        i_category,
        SUM(total_net_loss) AS category_total_net_loss
    FROM aggregated
    GROUP BY i_category
),
ranked AS (
    SELECT
        a.i_category,
        a.month,
        a.hd_income_band_sk,
        a.total_net_loss,
        a.total_return_amount,
        a.return_count,
        a.avg_return_quantity,
        ct.category_total_net_loss,
        RANK() OVER (ORDER BY ct.category_total_net_loss DESC) AS category_rank,
        ROUND(a.total_net_loss / ct.category_total_net_loss * 100, 2) AS month_share_pct
    FROM aggregated a
    JOIN category_totals ct ON a.i_category = ct.i_category
)
SELECT
    i_category,
    month,
    hd_income_band_sk,
    total_net_loss,
    total_return_amount,
    return_count,
    avg_return_quantity,
    category_total_net_loss,
    category_rank,
    month_share_pct
FROM ranked
WHERE category_rank <= 10
ORDER BY category_rank, month
