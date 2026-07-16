WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        cd.cd_education_status,
        cd.cd_marital_status,
        hd.hd_vehicle_count,
        s.s_state,
        s.s_city,
        s.s_store_name,
        s.s_tax_percentage
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_returned_date_sk BETWEEN 20220101 AND 20221231
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count >= 2
      AND s.s_state IN ('CA', 'NY', 'TX')
),
aggregated AS (
    SELECT
        s_state,
        s_city,
        cd_education_status AS education_status,
        COUNT(*) AS returns_cnt,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(sr_net_loss) AS avg_net_loss,
        SUM(sr_return_quantity) AS total_return_qty
    FROM filtered_returns
    GROUP BY s_state, s_city, cd_education_status
    HAVING COUNT(*) >= 50
)
SELECT
    s_state,
    s_city,
    education_status,
    returns_cnt,
    total_net_loss,
    avg_net_loss,
    total_return_qty,
    RANK() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS loss_rank_state,
    ROUND(total_net_loss / NULLIF(returns_cnt, 0), 2) AS loss_per_return
FROM aggregated
ORDER BY s_state, loss_rank_state
LIMIT 100
