WITH promotion_item AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        p.p_cost,
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        i.i_class_id
    FROM promotion p
    FULL OUTER JOIN item i
        ON p.p_item_sk = i.i_item_sk
),

base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        cd.cd_gender,
        hd.hd_income_band_sk,
        r.r_reason_id,
        r.r_reason_desc,
        cp.cp_catalog_page_id,
        wp.wp_url,
        ws.web_name
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
        AND cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        OR wp.wp_access_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
        OR ws.web_close_date_sk = d.d_date_sk
),

joined AS (
    SELECT
        b.*,
        pi.i_brand,
        pi.i_class_id,
        pi.i_current_price
    FROM base b
    JOIN promotion_item pi
        ON b.sr_item_sk = pi.i_item_sk
),

with_rev AS (
    SELECT
        j.*,
        rev.revenue_estimate
    FROM joined j
    CROSS JOIN LATERAL (
        SELECT j.sr_return_quantity * COALESCE(j.i_current_price, 0) AS revenue_estimate
    ) rev
),

agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_brand,
        cp_catalog_page_id,
        wp_url,
        web_name,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_count,
        SUM(revenue_estimate) AS total_revenue_estimate,
        CASE
            WHEN SUM(sr_return_amt) > 10000 THEN 'HIGH'
            WHEN SUM(sr_return_amt) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_level
    FROM with_rev
    WHERE
        d_year = 2001
        AND i_class_id IN (10, 15)
        AND r_reason_id = 'AAAAAAAAPAAAAAAA'
    GROUP BY
        d_year,
        d_month_seq,
        i_brand,
        cp_catalog_page_id,
        wp_url,
        web_name
)

SELECT
    a.d_year,
    a.d_month_seq,
    a.i_brand,
    a.cp_catalog_page_id,
    a.wp_url,
    a.web_name,
    a.total_return_amount,
    a.total_net_loss,
    a.returns_count,
    a.total_revenue_estimate,
    a.return_level,
    DENSE_RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS yearly_return_rank
FROM agg a
ORDER BY a.total_return_amount DESC
OFFSET 0
LIMIT 100
