WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        d.d_date,
        d.d_year,
        i.i_item_sk,
        i.i_brand,
        i.i_current_price,
        r.r_reason_desc,
        cc.cc_company,
        cc.cc_sq_ft,
        cp.cp_type,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 50
      AND r.r_reason_desc LIKE '%warranty%'
      AND cc.cc_sq_ft > 0
      AND cp.cp_type = 'web'
      AND wr.wr_return_quantity > 0
),
aggregated_returns AS (
    SELECT
        d_year,
        i_brand,
        r_reason_desc,
        SUM(wr_return_amt) AS sum_return_amt,
        COUNT(*) AS cnt_returns,
        AVG(wr_return_amt) AS avg_return_amt
    FROM filtered_returns
    GROUP BY d_year, i_brand, r_reason_desc
),
unioned AS (
    SELECT d_year, i_brand, sum_return_amt FROM aggregated_returns WHERE avg_return_amt > 20
    UNION ALL
    SELECT d_year, i_brand, sum_return_amt FROM aggregated_returns WHERE cnt_returns >= 10
),
final_agg AS (
    SELECT
        d_year,
        SUM(sum_return_amt) AS total_sum_return,
        COUNT(*) AS brand_count
    FROM unioned
    GROUP BY d_year
    HAVING SUM(sum_return_amt) > 1000
)
SELECT
    f.d_year,
    f.total_sum_return,
    f.brand_count
FROM final_agg f
WHERE NOT EXISTS (
    SELECT 1 FROM call_center cc2
    WHERE cc2.cc_company = f.brand_count
      AND cc2.cc_sq_ft < 0
)
LIMIT 100
