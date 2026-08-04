WITH agg_returns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_store_sk,
        sr_reason_sk,
        sr_cdemo_sk,
        sr_hdemo_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_returned_date_sk, sr_item_sk, sr_store_sk, sr_reason_sk, sr_cdemo_sk, sr_hdemo_sk
),
joined_all AS (
    SELECT
        ar.sr_store_sk,
        s.s_store_id,
        s.s_state,
        ar.sr_returned_date_sk,
        d_ret.d_year,
        ar.total_return_amt,
        ar.cnt_returns,
        i.i_item_id,
        i.i_current_price,
        cd.cd_gender,
        ib.ib_lower_bound,
        cp.cp_department,
        wp.wp_max_ad_count,
        r.r_reason_desc
    FROM agg_returns ar
    JOIN item i ON ar.sr_item_sk = i.i_item_sk
    JOIN store s ON ar.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret ON ar.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd ON ar.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ar.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON ar.sr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2000
      AND i.i_current_price > 20
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND ib.ib_lower_bound >= 50000
      AND cp.cp_department = 'Books'
      AND wp.wp_max_ad_count <= 2
)
SELECT *
FROM (
    SELECT
        DISTINCT s_store_id,
        d_year,
        total_return_amt,
        cnt_returns,
        RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS store_return_rank,
        CASE WHEN r_reason_desc = 'Customer Not Satisfied' THEN 'Issue' ELSE 'Other' END AS issue_flag
    FROM joined_all
) a
EXCEPT
SELECT
    s_store_id,
    d_year,
    total_return_amt,
    cnt_returns,
    store_return_rank,
    issue_flag
FROM (
    SELECT
        s.s_store_id,
        d_ret.d_year,
        ar.total_return_amt,
        ar.cnt_returns,
        RANK() OVER (PARTITION BY d_ret.d_year ORDER BY ar.total_return_amt DESC) AS store_return_rank,
        CASE WHEN r.r_reason_desc = 'Customer Not Satisfied' THEN 'Issue' ELSE 'Other' END AS issue_flag
    FROM agg_returns ar
    JOIN store s ON ar.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret ON ar.sr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON ar.sr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_year = 2000
      AND r.r_reason_desc = 'Customer Not Satisfied'
) b
ORDER BY total_return_amt DESC
LIMIT 100
