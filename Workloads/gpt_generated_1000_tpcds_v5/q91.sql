WITH cat_agg AS (
    SELECT
        cr_reason_sk,
        cr_call_center_sk,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_quantity > 10
      AND cr_return_amount > 0
      AND cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cr_reason_sk, cr_call_center_sk, cr_returned_date_sk
)
SELECT
    s.s_store_name,
    cc.cc_name,
    r.r_reason_desc,
    d_store.d_year,
    cat_agg.total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    (cat_agg.total_net_loss + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS combined_net_loss,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = cat_agg.cr_reason_sk
    ) AS avg_return_amount_by_reason
FROM cat_agg
JOIN reason r
  ON cat_agg.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
  ON cat_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cat
  ON cat_agg.cr_returned_date_sk = d_cat.d_date_sk
JOIN store_returns sr
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
  ON sr.sr_returned_date_sk = d_store.d_date_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_returns wr
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_web
  ON wr.wr_returned_date_sk = d_web.d_date_sk
WHERE cd.cd_marital_status = 'M'
  AND cd.cd_dep_college_count >= 2
  AND s.s_state = 'CA'
  AND d_store.d_year = 2001
  AND r.r_reason_desc LIKE '%damage%'
  AND cat_agg.total_return_amount > 500
GROUP BY
    s.s_store_name,
    cc.cc_name,
    r.r_reason_desc,
    d_store.d_year,
    cat_agg.total_return_amount,
    cat_agg.total_net_loss,
    cat_agg.cr_reason_sk
ORDER BY combined_net_loss DESC
LIMIT 100
