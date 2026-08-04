WITH sales_demo AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        wp.wp_url,
        wp.wp_type,
        cs.cs_order_number,
        wr.wr_web_page_sk
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON cs.cs_order_number = wr.wr_order_number
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_coupon_amt > 500
      AND cs.cs_ext_ship_cost BETWEEN 300 AND 5000
      AND hd.hd_buy_potential = '501-1000'
      AND wr.wr_return_amt_inc_tax < 1500
      AND cd.cd_gender = 'M'
      AND hd.hd_dep_count > 0
),
agg_per_customer AS (
    SELECT
        cs_bill_customer_sk,
        hd_buy_potential,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(wr_return_amt_inc_tax) AS total_returns,
        COUNT(DISTINCT cs_bill_cdemo_sk) AS demo_count
    FROM sales_demo
    GROUP BY cs_bill_customer_sk, hd_buy_potential
),
url_expansion AS (
    SELECT
        wp.wp_web_page_sk,
        part AS url_segment
    FROM web_page wp
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(part)
    WHERE wp.wp_type = 'content'
)
SELECT
    a.cs_bill_customer_sk,
    a.hd_buy_potential,
    a.total_sales,
    a.total_returns,
    a.demo_count,
    (a.total_sales - a.total_returns) / NULLIF(a.total_sales, 0) AS profit_margin,
    ue.url_segment
FROM agg_per_customer a
JOIN (
    SELECT DISTINCT wp.wp_web_page_sk
    FROM web_page wp
    WHERE wp.wp_type = 'content'
) filtered_wp
    ON TRUE               -- cross‑join to keep rows but allow the EXISTS filter below
LEFT JOIN url_expansion ue
    ON filtered_wp.wp_web_page_sk = ue.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_type = 'content'
      AND wp2.wp_url LIKE '%catalog%'
)
ORDER BY profit_margin DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
