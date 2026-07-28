WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_date,
        d.d_year,
        t.t_hour,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cd.cd_demo_sk,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_type,
        r.r_reason_desc,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        w.web_site_sk,
        w.web_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cd.cd_credit_rating IN ('Good', 'High Risk')
      AND cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND s.s_state = 'WA'
      AND t.t_hour BETWEEN 8 AND 18
),
agg AS (
    SELECT
        b.d_date,
        b.s_store_name,
        b.s_state,
        b.cp_department,
        b.cr_returned_date_sk,
        SUM(b.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE 
            WHEN SUM(b.cr_net_loss) > 10000 THEN 'High'
            WHEN SUM(b.cr_net_loss) > 5000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category,
        (SELECT AVG(cr2.cr_net_loss)
         FROM catalog_returns cr2
         WHERE cr2.cr_returned_date_sk = b.cr_returned_date_sk) AS avg_daily_net_loss
    FROM base b
    GROUP BY b.d_date, b.s_store_name, b.s_state, b.cp_department, b.cr_returned_date_sk
    HAVING SUM(b.cr_net_loss) > 1000
)
SELECT
    a.d_date,
    a.s_store_name,
    a.s_state,
    a.cp_department,
    a.total_net_loss,
    a.return_cnt,
    a.loss_category,
    a.avg_daily_net_loss,
    RANK() OVER (PARTITION BY a.d_date ORDER BY a.total_net_loss DESC) AS loss_rank
FROM agg a
ORDER BY a.d_date DESC, loss_rank
LIMIT 100
