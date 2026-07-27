WITH wr_agg AS (
    SELECT
        wr_item_sk,
        wr_returned_date_sk,
        wr_refunded_cdemo_sk,
        wr_returning_cdemo_sk,
        wr_web_page_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_tax) AS avg_return_tax,
        SUM(wr_fee) AS total_fee
    FROM web_returns
    WHERE wr_fee > 10.00
      AND wr_return_tax < 50.00
      AND wr_return_quantity >= 1
    GROUP BY
        wr_item_sk,
        wr_returned_date_sk,
        wr_refunded_cdemo_sk,
        wr_returning_cdemo_sk,
        wr_web_page_sk
)
SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    i.i_category,
    i.i_brand,
    cd_ref.cd_gender,
    cd_ref.cd_education_status,
    p.p_channel_email,
    p.p_discount_active,
    wp.wp_type,
    SUM(wr_agg.total_return_amt) AS sum_return_amt,
    SUM(wr_agg.total_fee) AS sum_fee,
    AVG(wr_agg.avg_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wr_agg.wr_item_sk) AS distinct_items,
    SUM(wr_agg.return_cnt) AS total_returns
FROM wr_agg
JOIN item i
    ON wr_agg.wr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON wr_agg.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ref
    ON wr_agg.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN web_page wp
    ON wr_agg.wr_web_page_sk = wp.wp_web_page_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_ret.d_year = 2001
  AND d_ret.d_month_seq BETWEEN 1200 AND 1210
  AND i.i_brand = 'BrandX'
  AND cd_ref.cd_gender = 'M'
  AND p.p_channel_email = 'Y'
  AND wp.wp_type = 'content'
  AND p.p_discount_active = 'Y'
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    i.i_category,
    i.i_brand,
    cd_ref.cd_gender,
    cd_ref.cd_education_status,
    p.p_channel_email,
    p.p_discount_active,
    wp.wp_type
ORDER BY sum_return_amt DESC
LIMIT 100
