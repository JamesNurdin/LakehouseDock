WITH joined AS (
    SELECT
        d.d_year,
        s.s_state,
        sm.sm_type,
        r.r_reason_desc,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        ss.ss_net_profit,
        ss.ss_sales_price
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
)
SELECT
    d_year,
    s_state,
    sm_type,
    r_reason_desc,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(cr_return_quantity) AS total_returns,
    AVG(ss_net_profit) AS avg_profit,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_sales_price) AS max_sales_price
FROM joined
WHERE d_year = 2001
  AND s_state = 'CA'
  AND sm_type = 'AIR'
  AND r_reason_desc = 'Damaged'
GROUP BY d_year, s_state, sm_type, r_reason_desc

UNION DISTINCT

SELECT
    d_year,
    s_state,
    sm_type,
    r_reason_desc,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(cr_return_quantity) AS total_returns,
    AVG(ss_net_profit) AS avg_profit,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_sales_price) AS max_sales_price
FROM joined
WHERE d_year = 2002
  AND s_state = 'TX'
  AND sm_type = 'RAIL'
  AND r_reason_desc = 'Customer Not Satisfied'
GROUP BY d_year, s_state, sm_type, r_reason_desc

ORDER BY total_net_loss DESC
LIMIT 100
