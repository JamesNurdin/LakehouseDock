WITH sales_agg AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        hd.hd_vehicle_count,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY i.i_category, cd.cd_gender, hd.hd_vehicle_count
),
returns_agg AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        hd.hd_vehicle_count,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY i.i_category, cd.cd_gender, hd.hd_vehicle_count
)
SELECT
    s.i_category,
    s.cd_gender,
    s.hd_vehicle_count,
    s.total_sales,
    s.total_profit,
    s.sales_cnt,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amt, 0) / s.total_sales ELSE 0 END AS return_rate,
    CASE WHEN s.total_sales > 0 THEN s.total_discount / s.total_sales ELSE 0 END AS avg_discount_rate
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
   AND s.cd_gender = r.cd_gender
   AND s.hd_vehicle_count = r.hd_vehicle_count
ORDER BY s.total_sales DESC
LIMIT 100
