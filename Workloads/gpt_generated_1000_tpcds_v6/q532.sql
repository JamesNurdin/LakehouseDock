WITH joined_data AS (
    SELECT
        cp.cp_catalog_number,
        cp.cp_type,
        i.i_brand,
        i.i_category,
        d.d_year,
        d.d_date,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        sr.sr_return_amt,
        ws.ws_net_paid
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = cs.cs_sold_date_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
        AND ws.ws_item_sk = cs.cs_item_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND cp.cp_type = 'monthly'
      AND i.i_brand = 'Brand#23'
      AND hd.hd_income_band_sk = 5
      AND r.r_reason_desc = 'Package was damaged'
),
aggregated AS (
    SELECT
        cp_catalog_number,
        i_brand,
        d_year,
        hd_buy_potential,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(sr_return_amt) AS total_returns,
        SUM(ws_net_paid) AS total_web_sales,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM joined_data
    GROUP BY cp_catalog_number, i_brand, d_year, hd_buy_potential
    HAVING SUM(cs_ext_sales_price) > 100000
)
SELECT
    cp_catalog_number,
    i_brand,
    d_year,
    hd_buy_potential,
    total_sales,
    avg_profit,
    order_cnt,
    total_returns,
    total_web_sales,
    sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
