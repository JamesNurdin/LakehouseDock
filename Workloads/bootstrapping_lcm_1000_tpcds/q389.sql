WITH agg AS (
    SELECT
        d.d_year AS return_year,
        d.d_moy AS return_month,
        i.i_category AS category,
        i.i_brand AS brand,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_count,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_tax) AS total_tax,
        MAX(i.i_current_price) AS max_current_price,
        MIN(i.i_wholesale_cost) AS min_wholesale_cost
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_state = 'CA'
    GROUP BY
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_brand,
        cd_ref.cd_gender,
        cd_ret.cd_gender
)
SELECT
    return_year,
    return_month,
    category,
    brand,
    refunded_gender,
    returning_gender,
    total_net_loss,
    total_return_amount,
    total_return_amount - total_net_loss AS net_gain,
    avg_return_qty,
    return_count,
    total_fee,
    total_tax,
    max_current_price,
    min_wholesale_cost,
    ROUND(total_net_loss / NULLIF(total_return_amount, 0), 4) AS loss_ratio,
    RANK() OVER (PARTITION BY return_year, return_month ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
WHERE total_net_loss > 0
ORDER BY return_year, return_month, net_loss_rank
LIMIT 100
