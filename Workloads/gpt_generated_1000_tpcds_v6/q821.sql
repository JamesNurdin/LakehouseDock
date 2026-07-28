WITH sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_cdemo_sk,
        sr_addr_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt,
        MIN(sr_return_quantity) AS min_qty,
        MAX(sr_return_quantity) AS max_qty
    FROM store_returns
    WHERE sr_return_amt > 100
    GROUP BY sr_returned_date_sk, sr_cdemo_sk, sr_addr_sk
)
SELECT
    cc.cc_name,
    d_ret.d_year,
    cd.cd_gender,
    ca.ca_state,
    wp.wp_type,
    SUM(sr_agg.total_return_amt) AS sum_return_amt,
    SUM(sr_agg.total_return_tax) AS sum_return_tax,
    SUM(sr_agg.return_cnt) AS total_returns,
    MIN(sr_agg.min_qty) AS overall_min_qty,
    MAX(sr_agg.max_qty) AS overall_max_qty
FROM sr_agg
JOIN date_dim d_ret ON sr_agg.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr_agg.sr_addr_sk = ca.ca_address_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
WHERE
    cc.cc_division IN (1, 3, 5)
    AND cc.cc_rec_end_date = DATE '2001-12-31'
    AND wp.wp_max_ad_count >= 2
    AND wp.wp_rec_start_date BETWEEN DATE '1999-09-04' AND DATE '2001-09-03'
    AND cd.cd_dep_college_count >= 3
    AND cd.cd_dep_employed_count <= 5
    AND d_ret.d_year = 2000
GROUP BY
    cc.cc_name,
    d_ret.d_year,
    cd.cd_gender,
    ca.ca_state,
    wp.wp_type
ORDER BY sum_return_amt DESC
LIMIT 100
