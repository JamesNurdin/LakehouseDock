WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_date,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1211
      AND hd.hd_buy_potential = '1001-5000'
      AND hd.hd_dep_count >= 2
      AND t.t_hour BETWEEN 9 AND 17
      AND d.d_holiday = 'N'
    GROUP BY cs.cs_sold_date_sk, d.d_date
)
SELECT
    d2.d_date,
    s.total_sales,
    s.total_profit,
    s.sales_cnt,
    COALESCE(wp.wp_type, 'NoPage') AS page_type,
    COALESCE(ws.web_country, 'Unknown') AS site_country,
    COALESCE(inv.inv_quantity_on_hand, 0) AS qty_on_hand,
    RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank,
    CASE
        WHEN s.total_sales > (SELECT AVG(total_sales) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM sales_agg s
JOIN date_dim d2 ON s.cs_sold_date_sk = d2.d_date_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d2.d_date_sk
LEFT JOIN web_returns wr ON s.cs_sold_date_sk = wr.wr_returned_date_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d2.d_date_sk
WHERE inv.inv_quantity_on_hand > 0
  AND ws.web_country = 'United States'
  AND wp.wp_type = 'product'
  AND d2.d_current_week = 'N'
  AND d2.d_following_holiday = 'N'
ORDER BY profit_rank
LIMIT 100
