WITH sales_agg AS (
    SELECT
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_ext_sales_price > 0
    GROUP BY cs_bill_cdemo_sk, cs_bill_hdemo_sk
),
joined AS (
    SELECT
        sa.cs_bill_cdemo_sk,
        sa.cs_bill_hdemo_sk,
        sa.total_sales,
        sa.total_profit,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type
    FROM sales_agg sa
    JOIN customer_demographics cd
        ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
      AND hd.hd_vehicle_count >= 1
      AND wp.wp_url LIKE 'http://www.%'
)
SELECT
    wp_web_page_id,
    wp_url,
    wp_type,
    SUM(total_sales) AS page_total_sales,
    SUM(total_profit) AS page_total_profit,
    SUM(wr_return_amt) AS page_total_returns,
    CASE
        WHEN SUM(total_profit) > SUM(wr_return_amt) THEN 'Profit > Returns'
        ELSE 'Loss'
    END AS profit_vs_return,
    ROW_NUMBER() OVER (ORDER BY SUM(total_profit) DESC) AS profit_rank,
    (SELECT AVG(cs_net_profit) FROM catalog_sales) AS overall_avg_profit,
    CASE
        WHEN SUM(total_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM joined
GROUP BY wp_web_page_id, wp_url, wp_type
HAVING SUM(total_sales) > 10000
ORDER BY profit_rank
LIMIT 100
