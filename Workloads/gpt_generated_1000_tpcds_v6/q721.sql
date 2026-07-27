WITH sales_returns AS (
    SELECT
        ss.ss_item_sk,
        i.i_brand,
        i.i_category,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_returns,
        COUNT(wr.wr_return_quantity) AS return_cnt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price BETWEEN 10 AND 200
      AND ib.ib_lower_bound >= 20000
      AND hd.hd_vehicle_count <= 2
      AND ss.ss_ext_sales_price > 0
    GROUP BY ss.ss_item_sk, i.i_brand, i.i_category,
             ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound,
             hd.hd_buy_potential
),
ranked_sales AS (
    SELECT
        sr.i_brand,
        sr.i_category,
        sr.hd_buy_potential,
        sr.ib_lower_bound,
        sr.total_sales,
        sr.total_returns,
        sr.sales_cnt,
        sr.return_cnt,
        (sr.total_sales - sr.total_returns) AS net_sales,
        RANK() OVER (PARTITION BY sr.i_category ORDER BY sr.total_sales DESC) AS sales_rank,
        SUM(sr.total_sales) OVER (PARTITION BY sr.hd_buy_potential) AS sales_by_potential
    FROM sales_returns sr
    WHERE sr.total_sales > (SELECT AVG(total_sales) FROM sales_returns)
      AND sr.return_cnt < 5
)
SELECT
    rs.i_brand,
    rs.i_category,
    rs.hd_buy_potential,
    rs.ib_lower_bound,
    rs.total_sales,
    rs.total_returns,
    rs.sales_cnt,
    rs.return_cnt,
    rs.net_sales,
    rs.sales_rank,
    rs.sales_by_potential
FROM ranked_sales rs
WHERE rs.net_sales > 1000
ORDER BY rs.total_sales DESC
LIMIT 100
