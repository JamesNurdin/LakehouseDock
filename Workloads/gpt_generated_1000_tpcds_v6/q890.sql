WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d.d_year,
        d.d_week_seq,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        hd_ref.hd_vehicle_count AS refunded_vehicle_cnt,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_ret.hd_vehicle_count AS returning_vehicle_cnt,
        s.s_manager,
        s.s_company_name,
        w.web_class,
        w.web_name
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_week_seq BETWEEN 6 AND 12
        AND hd_ref.hd_buy_potential = '501-1000'
        AND hd_ref.hd_vehicle_count >= 1
        AND s.s_manager = 'William Ward'
        AND w.web_class = 'Retail'
        AND cr.cr_return_quantity > 0
),
agg AS (
    SELECT
        d_year,
        s_manager,
        web_class,
        refunded_buy_potential,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MIN(cr_return_quantity) AS min_quantity,
        MAX(cr_net_loss) AS max_net_loss
    FROM base
    GROUP BY
        d_year,
        s_manager,
        web_class,
        refunded_buy_potential
)
SELECT
    d_year,
    s_manager,
    web_class,
    refunded_buy_potential,
    total_return_amount,
    avg_return_tax,
    return_cnt,
    min_quantity,
    max_net_loss,
    SUM(total_return_amount) OVER (PARTITION BY s_manager ORDER BY total_return_amount DESC) AS manager_cumulative_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
